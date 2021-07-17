# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-stop instance-id"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    instance-id   the instance ID to stop"
    echo
}

function stop_instance() {
    case $1 in
        [1-9]*)
            local instance="$1"
            shift
            instance_switch "$instance"
            instance_stop "$instance" "$@"
            ;;
        *)
            usage
            ;;
    esac
}

stop_instance "$@"
