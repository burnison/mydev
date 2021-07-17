# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev builds-list-all [source]"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    source        an optional source"
    echo
}

function list_all_builds() {
    if [ $# -gt 1 ]; then
        usage
        exit
    fi

    for s in `ls $MYDEV_SOURCES` ; do
        if [ -n "$1" -a ! "$s" = "$1" ]; then
            continue
        fi

        cd "$MYDEV_SOURCES/$s"

        for b in $(git branch -r -l --format='%(refname:short)' | grep '^origin/[0-9].[0-9]$'); do
            local build=$(branch_to_build $s $b)
            if [ -d "$MYDEV_BUILDS/$build" ]; then
                echo "* $build  ($b)"
            else
                echo "  $build  ($b)"
            fi
        done
    done
}

list_all_builds "$@"
