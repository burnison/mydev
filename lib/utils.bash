function branch_to_build() {
    local repo="$1"
    local branch=$(echo "$2" | sed 's_origin/__g')
    echo "${repo}-${branch}"
}

function instance_build() {
    local instance="$1"
    local build_link="$MYDEV_INSTANCES/$instance/build"
    if [ ! -L "$build_link" ]; then
        echo ''
    else
        local build_path="$(readlink $build_link)"
        basename "$build_path"
    fi
}

function port_from_instance() {
    # 5.6 instance 02 -> 35602
    echo $((30000 + $1))
}

function is_instance() {
    local instance="$1"
    local instance_path="$(instance_path_for_instance $instance)"
    test -d "$instance_path/data/mysql"
}

function is_build() {
    local build="$1"
    local build_path=$(build_path_for_build "$build")
    test -f "$build_path/install/bin/mysqld"
}

function build_path_for_build() {
    echo "$MYDEV_BUILDS/$1"
}

function build_path_for_instance() {
    local instance="$1"
    local build=$(instance_build "$instance")
    build_path_for_build "$build"
}

function instance_path_for_instance() {
    echo "$MYDEV_INSTANCES/$1"
}

function instance_switch() {
    local instance="$1"
    local build=$(instance_build "$instance")
    if ! is_build "$build" ; then
        echo "ERROR: Specified instance does not exist or has no associated build."
        return 1
    else
        local build_path=$(build_path_for_build "$build")
        local instance_path=$(instance_path_for_instance "$instance")

        . "$build_path/build/VERSION.dep"
        export MYSQL_VERSION_MAJOR
        export MYSQL_VERSION_MINOR
        export MYSQL_VERSION="$MYSQL_VERSION_MAJOR.$MYSQL_VERSION_MINOR"
        export MYSQL_HOME="$instance_path"
        export PATH="$build_path/install/bin:$build_path/install/scripts:$PATH"
    fi
}

function instance_connect() {
    local instance_path="$(instance_path_for_instance "$1")"
    shift
    mysql -h localhost --socket="${instance_path}/mysql.sock" -u root --password='' "$@"
}

function instance_start() {
    local instance_path=$(instance_path_for_instance "$1")
    shift
    mysqld --defaults-file="$instance_path/my.cnf" "$@"
}

function instance_debug() {
    local instance_path=$(instance_path_for_instance "$1")
    shift
    lldb -- mysqld --defaults-file="$instance_path/my.cnf" --debug="o,/dev/stdout" "$@"
}

function instance_await() {
    echo -n 'Waiting for start-up to complete'
    while ! instance_ping $1 &>/dev/null ; do
        echo -n '.'
        sleep 1
    done
    echo
}

function instance_call_admin() {
    local instance="$1"
    local cmd="$2"
    local user="${3:-root}"
    local password="${4}"

    local port=$(port_from_instance "$instance")
    mysqladmin --no-defaults \
        -h 127.0.0.1 -P $port \
        -u "$user" --password="$password" \
        "$cmd" 2> >(sed '/^Warning: Using a password/d')
}

function instance_ping() {
    local instance="$1"
    shift
    instance_call_admin "$instance" ping ping ping
}

function instance_stop() {
    local instance="$1"
    shift
    instance_call_admin "$instance" shutdown "$@"
}
