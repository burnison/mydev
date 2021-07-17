# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-status [instance-id]"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    instance-id   the instance ID to status (optional)"
    echo
}

function check_status() {
    local instance="$1"
    instance_ping "$instance" &>/dev/null && echo 'running' || echo 'stopped'
}

function instance_status() {
    if [ $# -eq 0 ]; then
        for instance in $(ls $MYDEV_INSTANCES); do
            if is_instance "$instance" ; then
                echo -en "$instance\t"
                check_status "$instance"
            fi
        done
    else
        case $1 in
            [1-9]*)
                check_status $1
                ;;
            *)
                usage
                ;;
        esac
    fi
}

instance_status "$@"
