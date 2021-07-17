# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-connect instance-id"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    instance-id   the instance ID of which to connect"
    echo
}

function connect_to_instance() {
    case $1 in
        [1-9]*)
            local instance=$1
            shift
            instance_switch "$instance"
            instance_connect "$instance" "$@"
            ;;
        *)
            usage
            ;;
    esac
}

connect_to_instance "$@"
