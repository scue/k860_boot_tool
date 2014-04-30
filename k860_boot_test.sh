#!/bin/bash - 
#===============================================================================
#
#          FILE: boot_test.sh
# 
#         USAGE: ./boot_test.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: linkscue(scue),
#  ORGANIZATION: 
#       CREATED: 2013年08月05日 03时04分29秒 HKT
#      REVISION:  ---
#===============================================================================

# fun: usage
usage(){
    echo
    echo "==> 联想K860/i boot 解压、打包工具"
    echo
    echo -en "\e[0;31m" # color: red
    echo "==> 使用: $(basename $0) repack|unpack."
    echo "==> 备注: 此解包、打包boot的方法已在VIBE版本中失效"
    echo -en "\e[0m"
    echo
    exit
}

# detect: help
if [[ ${1} != "" ]]; then
    case ${1} in
        "-h" | "--help" | "-help" )
            usage
            ;;
    esac
fi

test -z $1 && usage

self=$(readlink -f $0)
self_dir=$(dirname $self)
unpack_bootimage=boot.img
repack_bootimage=boot_new.img
device_specify_name=0123456789ABCDEF

# tool location
adb_tool=$self_dir/adb
fastboot_tool=$self_dir/fastboot
mkbootfs_tool=$self_dir/mkbootfs
mkimage_tool=$self_dir/mkimage
minigzip_tool=$self_dir/minigzip
mkbootimg_tool=$self_dir/mkbootimg
bootimg_tool=$self_dir/bootimg.py

if [[ "$1" == "unpack" ]]; then
    if [[ ! -f $unpack_bootimage ]]; then
        echo "can't find a boot.img named $unpack_bootimage"
        exit 1
    fi
    $bootimg_tool --unpack-bootimg $unpack_bootimage
    dd if=ramdisk of=ramdisk.gz bs=64 skip=1
    mv ramdisk ramdisk.bak
    if [[ -d root/ ]]; then
        rm -rf root.bak 2>/dev/null
        mv root root.bak
    fi
    mkdir root
    cd root
    gzip -d -c ../ramdisk.gz | cpio -i
    cd -                                        # goto oldwd
    echo "unpack from $unpack_bootimage done"
fi

if [[ "$1" == "repack" ]]; then
    # reboot device to bootloader mod
    if [[ "$($adb_tool devices | grep $device_specify_name)" != "" ]]; then
        $adb_tool -s $device_specify_name reboot bootloader
    fi
    # repack root to ramdisk
    if [[ ! -d root/ ]]; then
        echo "can't find a directory nameed 'root/'"
        exit 1
    fi
    $mkbootfs_tool root | $minigzip_tool > ramdisk.img.cpio
    # add ramdisk header
    $mkimage_tool -A ARM -O Linux -T ramdisk -C none -a 0x40800000 -e 0x40800000 -n ramdisk -d ramdisk.img.cpio ramdisk.img.cpio.gz
    # make boot.img
    $mkbootimg_tool --kernel kernel --ramdisk ramdisk.img.cpio.gz --cmdline "" --base 0x10000000 --pagesize 2048 --output $repack_bootimage
    #flash boot.img
    $fastboot_tool flash boot $repack_bootimage
    $fastboot_tool reboot
    echo "repack to $repack_bootimage done"
fi
