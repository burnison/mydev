# -*- sh -*-

function usage() {
    echo "usage: mydev builds-list"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
}

function list_builds() {
    if [ $# -ne 0 ]; then
        usage
    else
        for build in `ls $MYDEV_BUILDS` ; do
            echo "$build"
        done
    fi
}

list_builds "$@"
