function mysqlenv_get_dir() {
    local -r mydev_dir="${(%):-%x}"
    echo "${mydev_dir%/*}"
}

if ! (return 0 2> /dev/null); then
    echo 'ERROR: This file must be sourced, not executed.'
    exit 1
fi

export MYDEV_DIR="$(mysqlenv_get_dir)"
export MYDEV_BIN="$MYDEV_DIR/bin"
export MYDEV_LIB="$MYDEV_DIR/lib"
export MYDEV_SHIMS="$MYDEV_DIR/shims"

export MYDEV_INSTANCES="$MYDEV_DIR/instances"
export MYDEV_BUILDS="$MYDEV_DIR/builds"
export MYDEV_SOURCES="$MYDEV_DIR/sources"
mkdir -p "$MYDEV_INSTANCES" "$MYDEV_BUILDS" "$MYDEV_SOURCES"

export PATH="${MYDEV_BIN}:${MYDEV_SHIMS}/:${PATH}"
