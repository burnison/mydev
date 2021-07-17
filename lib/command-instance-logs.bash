# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-logs instance-id"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    instance-id   the instance ID to start"
    echo
}

function show_instance_logs() {
    if [ $# -ne 1 ]; then
        usage
        exit 1
    fi

    local instance=$1
    if ! is_instance $1; then
        echo "ERROR: Specified instance, $1, is not an instance!"
        exit 1
    fi

    local instance_path=$(instance_path_for_instance "$1")
    local pager=${PAGER:-less}
    $pager "$instance_path/log/mysql-error.log"
}

show_instance_logs "$@"
