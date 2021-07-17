# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev instance-switch instance-id"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    instance-id   the instance ID of which to switch builds"
    echo
}

function switch_to_instance() {
    case $1 in
        [1-9]*)
            # This is ridiculously hacky, but it solves the prolem. Having
            # something that's a bit more shim-like may be a better idea.
            local instance="$1"
            local build=$(instance_build "$instance")
            local build_path=$(build_path_for_build "$build")

            rm -f "$MYDEV_SHIMS"
            ln -sf "$build_path/install/bin" "$MYDEV_SHIMS"

            ;;
        *)
            usage
            ;;
    esac
}

switch_to_instance "$@"
