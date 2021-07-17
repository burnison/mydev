# -*- sh -*-

. "$MYDEV_LIB/utils.bash"

function usage() {
    echo "usage: mydev builds-recompile build"
    echo
    echo "arguments:"
    echo "    -h|--help     show this help screen"
    echo
    echo "    build         the build"
    echo
    echo example: mydev builds-recompile percona-server-5.6
    echo
}

function parse_version() {
    local version_file="$1/VERSION"
    if [ ! -f "$version_file" ]; then
        version_file="$1/MYSQL_VERSION"
    fi

    while read line; do
        eval "local $line"
    done < $version_file

    echo "$MYSQL_VERSION_MAJOR.$MYSQL_VERSION_MINOR"
}

function recompile_build() {
    if [ $# -ne 1 ]; then
        usage
        exit
    fi

    local build=$1
    if [ ! -d "$MYDEV_BUILDS/$build" ]; then
        echo "ERROR The build, $build, does not exists."
        exit 1
    fi


    local src_dir="$MYDEV_BUILDS/$build/src"
    local build_dir="$MYDEV_BUILDS/$build/build"
    local install_dir="$MYDEV_BUILDS/$build/install"
    mkdir -p $build_dir $install_dir


    local version=$(parse_version "$src_dir")
    if [[ (( $version == 5.6 )) ]]; then
        CXX_COMPILER=${CXX_COMPILER:-$(which g++-10)}
        C_COMPILER=${C_COMPILER:-$(which gcc-10)}

    elif [[ (( $version > 5.6 )) ]]; then
        CXX_FLAGS="-Wno-class-memaccess -Wno-parentheses -Wno-deprecated-copy ${CXX_FLAGS}"
        CXX_COMPILER=${CXX_COMPILER:-$(which g++)}
        C_COMPILER=${C_COMPILER:-$(which gcc)}
    fi

    cd $build_dir
    cmake \
        -DCMAKE_INSTALL_PREFIX=$install_dir \
        -DWITH_DEBUG=full -DCMAKE_BUILD_TYPE=Debug -DWITH_EDITLINE=bundled -DWITH_SSL=system -DWITH_COREDUMPER=0 \
        -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_EXAMPLE_STORAGE_ENGINE=1 -DWITHOUT_TOKUDB=1 -DWITHOUT_ROCKSDB=1 \
        -DCMAKE_CXX_COMPILER="${CXX_COMPILER}" -DCMAKE_C_COMPILER="${C_COMPILER}" \
        -DCMAKE_CXX_FLAGS="${CXX_FLAGS}" -DCMAKE_C_FLAGS="${C_FLAGS}" \
        -DDOWNLOAD_BOOST=1 -DWITH_BOOST=boost -DENABLE_DOWNLOADS=1 \
        $src_dir .

    make -j $(nproc) install
}

recompile_build "$@"
