# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev builds-add source branch"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    source        the source repository"
    echo "    branch        the build branch"
    echo
    echo example: mydev builds-add percona-server 5.6
    echo
}

function add_build() {
    if [ $# -ne 2 ]; then
        usage
        exit
    fi

    local repo=$1
    local branch=$2
    local worktree="${MYDEV_BUILDS}/$(branch_to_build $repo $branch)"

    if [ -d "$worktree" ]; then
        echo "ERROR The build, ${repo}-${branch} already exists."
        exit 1

    elif [ ! -d "$MYDEV_SOURCES/$repo" ]; then
        echo "ERROR: Unknown source, $repo. Did you add it?"
        exit 1
    fi

    cd $MYDEV_SOURCES/$repo
    if ! git show-ref "$branch" &>/dev/null ; then
        echo "ERROR: The branch, $branch, does not exist in $repo."
        exit 1
    fi

    git worktree add --force "${worktree}/src" "$branch"
}

add_build "$@"
