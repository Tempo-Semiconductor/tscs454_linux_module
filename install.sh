#!/bin/bash

root="$PWD"
kernel_src_dir="/usr/src/linux-headers-$(uname -r)"
# Raspberry pi is the default 
dt_overlay="rpi-redwood-overlay.dtbo"
dt_overlay_dir="/boot/overlays/"
install_all=true
install_codec=false
install_overlay=false
run_depmod=false
make_args=''

options=':d:t:a:b:h'

usage_str="$(basename "$0") [-h] [-d dir] [-i target] [-a args] -- Builds the TSCS454 kernel module

where:
    -h  show this help text
    -d  set the source directory
    -t  set the install targets codec or overlay
    -a  arguments to pass to make
    -b  board - options are rpi and bbb"

usage() { echo "$usage_str"; }

while getopts $options opt; do
    case ${opt} in
    d )
        kernel_src_dir="${OPTARG}"
        ;;
    t )
        install_all=false
        echo "$OPTARG"
        if [ "$OPTARG" = 'codec' ]; then
            install_codec=true
        elif [ "$OPTARG" = 'overlay' ]; then
            install_overlay=true
        else
            echo -e "\n *** Error: Unrecognized install target $OPTARG\n" >&2; usage; exit 1;
        fi
        ;;
    a )
        make_args="${OPTARG}"
        ;;
    b )
        if [ "$OPTARG" = 'bbb' ]; then
            dt_overlay="bbb-redwood-overlay.dtbo"
            dt_overlay_dir="/lib/firmware/"
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

if [ "$install_all" = true ] || [ "$install_codec" = true ]; then
    echo "Installing modules"
    make $make_args -C $kernel_src_dir M=$PWD modules_install
    run_depmod=true
fi

if [ "$install_all" = true ] || [ "$install_overlay" = true ]; then
    echo "Installing overlays"
    echo "overlay: $dt_overlay"
    echo "overlay_dir: $dt_overlay_dir"
    cp $dt_overlay $dt_overlay_dir
fi

if [ "$run_depmod" = true ]; then
    depmod -a
fi
