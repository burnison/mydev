# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-list"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
}

function instance_list() {
    case $# in
        0)
            for i in `ls $MYDEV_INSTANCES` ; do
                if is_instance "$i"; then
                    local build=$(instance_build $i)
                    echo "$i ($build)"
                fi
            done
            ;;
        *)
            usage
            ;;
    esac
}

instance_list "$@"
