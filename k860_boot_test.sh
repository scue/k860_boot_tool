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
    echo "==> 联想K860/i boot recovery 解压、打包工具"
    echo
    echo -en "\e[0;31m" # color: red
    echo "==> 使用: $(basename $0) repack|unpack."
    echo "==> 备注: 打包后会自动刷入手机，如不希望刷入，不连接联想手机即可"
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

# 输出信息
info(){
    echo -e "\e[0;32m==> ${@}\e[0m"
}

# 输出次级信息
infosub(){
    echo -e "\e[0;36m  --> ${@}\e[0m"
}

# 输出提示
tip(){
    echo -e "\e[0;35m==> ${@}\e[0m"
}

# 错误信息
err(){
    echo -e "\e[0;31m==> ${@}\e[0m"
}

# 次级错误信息
errsub(){
    echo -e "\e[0;31m  --> ${@}\e[0m"
}

if [[ "$1" == "unpack" ]]; then
    if [[ ! -f $unpack_bootimage ]]; then
        err "没有找到 boot.img 文件！"
        exit 1
    fi
    info "使用 bootimg.py 解压 $unpack_bootimage"
    $bootimg_tool --unpack-bootimg $unpack_bootimage
    info "去除 Ramdisk 多余首部信息"
    dd if=ramdisk of=ramdisk.gz bs=64 skip=1
    mv ramdisk ramdisk.bak
    if [[ -d root/ ]]; then
        test -d root.bak && \
            infosub "删除备份目录 root.bak" && \
            rm -rf root.bak 2>/dev/null
        infosub "备份 root/ 至 root.bak/"
        mv root root.bak
    fi
    mkdir root
    cd root
    info "解压 ramdisk.gz 至 root/ 目录"
    gzip -d -c ../ramdisk.gz | cpio -i
    cd -                                        # goto oldwd
    tip "解压 $unpack_bootimage 完成"
fi

if [[ "$1" == "repack" ]]; then
    # reboot device to bootloader mod
    if [[ "$($adb_tool devices | grep $device_specify_name)" != "" ]]; then
        info "重启手机至 fastboot/bootloader 模式"
        $adb_tool -s $device_specify_name reboot bootloader
    fi
    # repack root to ramdisk
    if [[ ! -d root/ ]]; then
        err "can't find a directory nameed 'root/'"
        exit 1
    fi
    info "打包 root/ 目录"
    $mkbootfs_tool root | $minigzip_tool > ramdisk.img.cpio
    # add ramdisk header
    info "添加 Ramdisk 文件首部信息"
    $mkimage_tool -A ARM -O Linux -T ramdisk -C none -a 0x40800000 -e 0x40800000 -n ramdisk -d ramdisk.img.cpio ramdisk.img.cpio.gz
    # make boot.img
    info "制作 $repack_bootimage 文件"
    $mkbootimg_tool --kernel kernel --ramdisk ramdisk.img.cpio.gz --cmdline "" --base 0x10000000 --pagesize 2048 --output $repack_bootimage
    #flash boot.img
    info "给手机刷入 $repack_bootimage"
    $fastboot_tool flash boot $repack_bootimage
    $fastboot_tool reboot
    tip "打包至 $repack_bootimage 完成"
fi
