# -*- sh -*-

function usage() {
    echo "usage: mydev sources-list"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
}

function source_list() {
    case $# in
        0)
            for s in `ls $MYDEV_SOURCES` ; do
                echo "$s"
            done
            ;;
        *)
            usage
            ;;
    esac
}

source_list "$@"
