# -*- sh -*-

set -e

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-create [-r source-instance-id [--logical]] [--no-shutdown] build instance-id"
    echo
    echo "options"
    echo "    -r|--replica-of INSTANCE  creates a new replica from this host using a physical restore"
    echo "    --logical                 used with -r to crate an instance from a logical restore"
    echo "    --no-shutdown             prevent the new instance from shutting down"
    echo
    echo "    build                     the MySQL build to use"
    echo "    instance                  the unique instance number"
    echo
    echo "example: mydev instance-create --replica-of 5601 --logical percona-server-5.6 5602"
}

function create_instance() {
    parse_args "$@"

    if is_instance "$instance_id" ; then
        echo "ERROR: Instance $instance_id already exists!"
        exit 1

    elif ! is_build "$build" ; then
        echo "ERROR: Specified build does not exist."
        exit 1

    elif test -n "$from_instance_id" && ! instance_ping "$from_instance_id" &>/dev/null ; then
        echo "ERROR: The instance, $from_instance_id, does not appear to be up."
        exit 1
    fi


    local instance_path=$(instance_path_for_instance "$instance_id")
    local build_path=$(build_path_for_build "$build")
    create_instance_filetree "$instance_path" "$build_path"

    instance_switch "$instance_id"
    create_instance_config "$instance_id" "$instance_path"
    if [ -n "$from_instance_id" -a -z "$logical" ]; then
        replicate_physical "$from_instance_id" "$instance_id" "$no_shutdown"

    else
        create_instance_database "$instance_id" "$instance_path"

        instance_start "$instance_id" &
        local pid=$!

        instance_await "$instance_id"
        if [ -n "$logical" ]; then
            replicate_logical "$from_instance_id" "$instance_id"
        else
            initial_setup "$instance_id"
        fi

        if [ -z "$no_shutdown" ]; then
            instance_stop "$instance_id"
            wait $pid
        fi
    fi
}

function create_instance_config() {
    export local instance_id=$1
    export local instance_port=$(port_from_instance $1)
    export local instance_path=$2

    local config="# Generated, but changes will persist.
[mysql]
user = root
host = 127.0.0.1
port = $instance_port

[xtrabackup]
user = root
host = 127.0.0.1
port = $instance_port

[mysqld]
server-id = $instance_id
report-host = 127.0.0.1
port = $instance_port

socket = $instance_path/mysql.sock
pid_file = $instance_path/mysql.pid
datadir = $instance_path/data
log-bin = $instance_path/binary/mysql-bin
relay-log = $instance_path/relay/relay-bin
log-error  = $instance_path/log/mysql-error.log
tmpdir = $instance_path/tmp
slow-query-log-file = $instance_path/log/mysql-slow.log

!include $MYDEV_DIR/etc/mysql/common.cnf
"
    echo -e "$config" > $instance_path/my.cnf
}

function create_instance_filetree() {
    local instance_path=$1
    local build_path=$2

    mkdir -p $instance_path/{binary,data,log,private,relay,tmp}
    if [ ! -L "$instance_path/build" ]; then
        ln -sf "$build_path" "$instance_path/build"
    fi

}

function create_instance_database() {
    local instance="$1"
    local instance_path="$2"

    # We need to use a temporary file instead of a file descriptor because
    # mysql_install_db spawns a subprocess, `mysqld --print-defaults`, that
    # cannot read from the privileged file descriptor.
    local tmp_config=$(mktemp)

    cat "$instance_path/my.cnf" > $tmp_config
    echo -e "[mysqld]\nread_only = 0\nsuper_read_only = 0\n" >> $tmp_config

    local build_path=$(build_path_for_instance "$instance")
    if [[ (($MYSQL_VERSION > 5.6)) ]]; then
        mysqld --defaults-file="$tmp_config" --basedir="$instance_path/build/install" --initialize-insecure
    else
        mysql_install_db --defaults-file="$tmp_config" --basedir="$instance_path/build/install"
    fi

    rm $tmp_config
}

function initial_setup() {
    local instance_id="$1"
    local port=$(port_from_instance "$instance_id")

    mysql --no-defaults -h 127.0.0.1 -P $port -u root -e "
        SET GLOBAL super_read_only = OFF;

        CREATE USER 'replication'@'127.0.0.1' IDENTIFIED BY 'replication';
        GRANT REPLICATION SLAVE ON *.* TO 'replication'@'127.0.0.1';

        CREATE USER 'ping'@'127.0.0.1' IDENTIFIED BY 'ping';
        GRANT USAGE ON *.* TO 'ping'@'127.0.0.1';

        CREATE DATABASE IF NOT EXISTS orchestrator;
        CREATE USER 'orchestrator'@'127.0.0.1' IDENTIFIED BY 'orchestrator';
        GRANT SUPER, PROCESS, REPLICATION SLAVE, RELOAD ON *.* TO 'orchestrator'@'127.0.0.1';
        GRANT SELECT ON mysql.slave_master_info TO 'orchestrator'@'127.0.0.1';
    "
}

function replicate_physical() {
    if ! xtrabackup --version &>/dev/null ; then
        echo 'ERROR: xtrabackup is not in your PATH. You can use `--logical` instead to perform a logical dump.'
        exit 1
    fi

    local no_shutdown=$3
    local to=$2
    local from=$1
    local from_port=$(port_from_instance $1)

    local backup_directory="$MYDEV_INSTANCES/$from.bak"


    xtrabackup \
        --defaults-file="$MYDEV_INSTANCES/$from/my.cnf" \
        --backup \
        --target-dir=$backup_directory

    xtrabackup \
        --defaults-file="$MYDEV_INSTANCES/$from/my.cnf" \
        --prepare \
        --target-dir=$backup_directory

    xtrabackup \
        --defaults-file="$MYDEV_INSTANCES/$to/my.cnf" \
        --move-back \
        --target-dir=$backup_directory

    local from_purged="$(cat $backup_directory/xtrabackup_binlog_info | cut -f3)"

    rm -rf $backup_directory

    instance_start "$instance_id" --skip-slave-start &
    local pid=$!

    instance_await "$to"

    # MySQL 5.7 and above include the purged GTIDs in the dump.
    to_purged=$(instance_connect $to -bsse 'SELECT @@global.gtid_purged;')
    if [ -z "$to_purged" ]; then
        instance_connect $to -e "
            RESET SLAVE ALL;
            SET GLOBAL gtid_purged='$from_purged';
        "
    fi

    change_replication_source "$from" "$to"

    if [ -z "$no_shutdown" ]; then
        instance_stop "$to"
        wait $pid
    fi
}

function replicate_logical() {
    local from=$1
    local from_port=$(port_from_instance "$from")

    local to=$2

    instance_connect $to -e "SET GLOBAL super_read_only=0;"
    mysqldump -u root -h 127.0.0.1 -P $from_port --all-databases --triggers --routines --events --set-gtid-purged=ON \
        | instance_connect $to
    change_replication_source "$from" "$to"
    instance_connect $to -e "SET GLOBAL super_read_only=1;"
}

function change_replication_source() {
    local from=$1
    local to=$2

    # For debug builds, we need to work around PS-7558 and stop InnoDB slow
    # query logging. We can restore it to full after the set-up.
    local verbosity=$(instance_connect $to -bsse "SELECT @@global.log_slow_verbosity;")
    instance_connect $to -e "SET GLOBAL log_slow_verbosity='minimal';"

    local super_read_only=$(instance_connect $to -bsse "SELECT @@global.super_read_only;")

    instance_connect $to -e "
        SET GLOBAL super_read_only = 0;
        CHANGE MASTER TO MASTER_HOST='127.0.0.1', MASTER_PORT=$from_port, MASTER_USER='replication', MASTER_PASSWORD='replication', MASTER_AUTO_POSITION=1;
        START SLAVE;
    "

    sleep 5

    # Flushing privileges sets the GTID executed bits, which taints the
    # replication stream. To get around this, we need to disable bin logging.
    instance_connect $to -e "
        SET SESSION sql_log_bin=0;
        FLUSH PRIVILEGES;
        SET SESSION sql_log_bin=1;

        SET GLOBAL super_read_only = ${super_read_only:-1};
        SET GLOBAL log_slow_verbosity='${verbosity:-full}';

        SHOW SLAVE STATUS\G
    "
}

function parse_args() {
    while true ; do
      case $1 in
        -r|--replica-of)
            shift
            from_instance_id=$1
            ;;
        --logical)
            logical=1
            ;;
        --no-shutdown)
            no_shutdown=1
            ;;
        *)
            break
            ;;
      esac
      shift || break
    done

    build=$1
    instance_id=$2

    if [ $# -ne 2 ]; then
        usage
        exit 1

    elif [[ ! "$instance_id" =~ ^[1-9][0-9]*$ ]]; then
        echo "ERROR: Provide an instance number as a whole number."
        usage
        exit 1

    elif [ -n "$logical" -a -z "$from_instance_id" ]; then
        echo "ERROR: Cannot specify logical restore without specifying source instance."
        usage
        exit 1
    fi
}

create_instance "$@"
