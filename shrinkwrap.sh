#!/bin/bash
if [ $# -eq 0 ]
  then
    echo "No arguments supplied. Usage:"
    echo "shrinkwrap.sh myimage.img"
    echo "Script will shrink the image to minimal size *in place*."
    echo "Be sure to make a copy of the image before running this script."
    exit 1
fi
set -e
sudo fdisk -l $1
sudo fdisk -l $1 > /tmp/fdisk.log

START=$(cat /tmp/fdisk.log | grep "83 Linux" | awk '{print $2}')

echo "START of partition: $START"

sudo losetup -d /dev/loop0 || echo "Good - no /dev/loop0 is already free"
sudo losetup /dev/loop0 $1
sudo partprobe /dev/loop0
sudo lsblk /dev/loop0
sudo e2fsck -f /dev/loop0p2
sudo resize2fs -p /dev/loop0p2 -M
sudo dumpe2fs -h /dev/loop0p2 | tee /tmp/dumpe2fs
# Calculate the size of the resized filesystem in 512 blocks which we'll need
# later for fdisk to also resize the partition add 16 blocks just to be safe
NEWSIZE=$(cat /tmp/dumpe2fs |& awk -F: '/Block count/{count=$2} /Block size/{size=$2} END{print count*size/512 +  16}')
echo "NEW SIZE of partition: $NEWSIZE  512-blocks"

# now pipe commands to fdisk
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk /dev/loop0 || echo "Ignore that error."
  p # print the in-memory partition table
  d # delete partition
  2 # partition 2
  n # new partition
  p # primary partition
  2 # partion number 2
  $START # start where the old partition started
  +$NEWSIZE  # new size in 512 blocks
    # ok
  p # print final result
  w # write the partition table
  q # and we're done
EOF

sudo fdisk -l $1
sudo fdisk -l $1 > /tmp/fdisk_new.log
sudo losetup -d /dev/loop0

FINALEND_BYTES=$(cat /tmp/fdisk_new.log | grep "83 Linux" | awk '{print ($3+1)*512}')
echo "TRUNCATE AT: $FINALEND_BYTES bytes"

# Truncate the image file on disk
sudo truncate -s $FINALEND_BYTES $1

# Fill the empty space with zeros for better compressability
sudo losetup /dev/loop0 $1
sudo partprobe /dev/loop0
sudo mkdir -p /tmp/mountpoint
sudo mount /dev/loop0p2 /tmp/mountpoint
sudo dd if=/dev/zero of=/tmp/mountpoint/zero.txt  status=progress || echo "Expected to fail with out of space"
sudo rm /tmp/mountpoint/zero.txt
df -h /tmp/mountpoint
sudo umount /tmp/mountpoint
lsblk
sudo rmdir /tmp/mountpoint

echo "We're done. Final info: "
sudo fdisk -l $1
sudo dumpe2fs -h /dev/loop0p2 | tee /tmp/dumpe2fs
sudo losetup -d /dev/loop0
