# -*- sh -*-

function usage() {
    echo "usage: mydev source-add [percona|mysql]"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
}

function source_add() {
    case $1 in
        percona)
            git clone https://github.com/percona/percona-server.git $MYDEV_SOURCES/percona-server
            ;;
        mysql)
            git clone https://github.com/mysql/mysql-server.git $MYDEV_SOURCES/mysql-server
            ;;
        *)
            usage
            ;;
    esac
}

source_add "$@"
