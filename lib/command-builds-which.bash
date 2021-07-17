# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev builds-which"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
}

function which_build() {
    case $# in
        0)
            test -L "$MYDEV_SHIMS" || exit
            real_path=$(readlink "${MYDEV_SHIMS}")
            build_path=$(dirname $(dirname "$real_path"))
            basename $build_path
            ;;
        *)
            usage
            ;;
    esac
}

which_build "$@"
