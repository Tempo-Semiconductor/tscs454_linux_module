#!/bin/bash

root="$PWD"
kernel_src_dir="/usr/src/linux-headers-$(uname -r)"
build_all=true
build_codec=false
build_overlay=false
make_args=''
dtc_path="dtc"
dt_overlay="rpi-redwood-overlay"
board="rpi"

options=':d:t:a:c:b:h'

usage_str="$(basename "$0") [-h] [-d dir] [-b target] [-a args] [-t dtc] -- Builds the TSCS454 kernel module

where:
    -h  show this help text
    -d  set the source directory
    -t  set the build targets codec or overlay
    -a  arguments to pass to make
    -c  specify an alternative dtc
    -b  board - options are rpi or bbb"

usage() { echo "$usage_str"; }

while getopts $options opt; do
    case ${opt} in
    d )
        kernel_src_dir="${OPTARG}"
        ;;
    t )
        build_all=false
        echo "$OPTARG"
        if [ "$OPTARG" = 'codec' ]; then
            build_codec=true
        elif [ "$OPTARG" = 'overlay' ]; then
            build_overlay=true
        else
            echo -e "\n *** Error: Unrecognized build target $OPTARG\n" >&2; usage; exit 1;
        fi
        ;;
    a )
        make_args="${OPTARG}"
        ;;
    c )
        dtc_path="${OPTARG}"
        ;;
    b )
        if [ ${OPTARG} = 'bbb' ]; then
            dt_overlay="bbb-redwood-overlay"
            board="bbb"
        fi
        ;;
    h )
        usage; exit 0;
        ;;
    \? )
        echo -e "\n *** Error: Unrecognized argument -$OPTARG\n" >&2; usage; exit 1;
        ;;
    : )
        echo -e "\n *** Error: Missing argument for -$OPTARG\n" >&2; usage; exit 1;
        ;;
    esac
done

echo "Kernel source directory: $kernel_src_dir/"
echo "Using make arguments: $make_args"

if [ "$build_all" = true ] || [ "$build_codec" = true ]; then
    echo "Building modules"
    make $make_args -B -C $kernel_src_dir M=$PWD modules
fi

if [ "$build_all" = true ] || [ "$build_overlay" = true ]; then
    echo "Building overlay"
    dtc_input="$dt_overlay.dts"
    if [ ${board} = 'bbb' ]; then
        include_dir="$kernel_src_dir/include/"
        cpp -nostdinc -I $include_dir -undef -x assembler-with-cpp "$dt_overlay.dts" > "$dt_overlay.tmp.dts"
        dtc_input="$dt_overlay.tmp.dts"
    fi
    $dtc_path -W no-unit_address_vs_reg -@ -I dts -O dtb -o "$dt_overlay.dtbo" $dtc_input 
fi
