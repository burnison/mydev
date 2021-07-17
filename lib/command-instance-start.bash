# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-start [-d] instance-id [mysql-args]"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo "    -d|--debug    run this as a debug build"
    echo
    echo "    instance-id   the instance ID to start"
    echo
}

function start_instance() {
    while true; do
        case $1 in
            -d|--debug)
                local debug=1
                ;;
            [1-9]*)
                local instance=$1
                shift
                break
                ;;
            *)
                usage
                exit
                ;;
        esac
        shift || break
    done

    instance_switch "$instance"
    if [ -z "$debug" ]; then
        instance_start "$instance" "$@"
    else
        instance_debug "$instance" "$@"
    fi
}

start_instance "$@"
