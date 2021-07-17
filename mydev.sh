function mysqlenv_get_dir() {
    local last_arg="$2"
    local dir="$1"
    if [ "${BASH_SOURCE[0]}" != "" ]; then
      dir="${BASH_SOURCE[0]}"
    elif [[ "$last_arg" == *".sh" ]]; then
      dir="$last_arg"
    fi
    echo $(dirname $dir)
}

if ! (return 0 2> /dev/null); then
    echo 'ERROR: This file must be sourced, not executed.'
    exit 1
fi

export MYDEV_DIR="$(mysqlenv_get_dir $0 $_)"
export MYDEV_BIN="$MYDEV_DIR/bin"
export MYDEV_LIB="$MYDEV_DIR/lib"
export MYDEV_SHIMS="$MYDEV_DIR/shims"

export MYDEV_INSTANCES="$MYDEV_DIR/instances"
export MYDEV_BUILDS="$MYDEV_DIR/builds"
export MYDEV_SOURCES="$MYDEV_DIR/sources"
mkdir -p "$MYDEV_INSTANCES" "$MYDEV_BUILDS" "$MYDEV_SOURCES"

export PATH="${MYDEV_BIN}:${MYDEV_SHIMS}/:${PATH}"
