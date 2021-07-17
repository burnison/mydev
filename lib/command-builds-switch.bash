# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev builds-switch build"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    build         the build to switch to"
    echo
}

function switch_to_build() {
    case $# in
        1)
            local build="$1"
            if ! is_build $build; then
                echo "ERROR: The specified build, $build, is not a known build."
                exit 1
            fi

            local build_path=$(build_path_for_build "$build")
            rm -f "$MYDEV_SHIMS"
            ln -sf "$build_path/install/bin" "$MYDEV_SHIMS"

            ;;
        *)
            usage
            ;;
    esac
}

switch_to_build "$@"
