# RaspberryPi Image Shrinkwrap

I often make images of Raspberry Pi sdcards for easy installation and cloning. 
Unfortunately the size of the image will always be that of the size of the card, 
which is usually much larger than the amount of actual data.
Thankfully there is a way to shrink an image, though every tutorial i've seen
online is cumbersome and manual (e.g. using gparted). Instead I wrote a script
that does it automatically and shrinks the image to it's minimal size.


## Copy the sd card over 


Find your sdcard device, might be /dev/sdb or /dev/mmcblk0 or other.

```bash
lsblk
```

Copy the image locally to an img file 
```bash
sudo dd bs=4M if=/dev/mmcblk0 of=myimage.img conv=fsync status=progress
```

## Shrink the image 
```
./shrinkwrap.sh myimage.img
```

## Copy the image to new sd card
```bash
sudo dd bs=4M if=myimage.img of=/dev/mmcblk0.img conv=fsync status=progress
```

## Boot from the card 

You can now resize the image back to take the full SD card size by going to:

```
sudo raspi-config
```

And then choose "Expand root partition to fill SD card" option under Advanced 
Options.
