# Making a minimal Linux distro from scratch (no gui)

> I would really like to thank [Nir Lichtman](https://github.com/nir9) ([YouTube](https://www.youtube.com/@nirlichtman)) for his video on [Making Linux distro from scratch](https://www.youtube.com/watch?v=QlzoegSuIzg) for the inspiration and the creation of this project, this guide changes up the video and make a written format to be read at your own pace.

This is a a guide on making your own minimal linux distro from scratch.

## The Structure
To make a simple distro we need mainly 3 things
1. **Kernal**: the main software that talks between the hardware and software, here its *Linux*.
2. **User space**: All the tools to actually use the os, Unix tools like `cd` and `ls`; we will use *Busybox*
3. **Bootloader**: Loads everything, the first piece of code that runs and loads the kernal. Not yet planned what will be used here.

In a simple terms the Bootloader loads the kernal, and kernal loads the userspace allowing you to interact.
```
Bootloader -> Kernal (Linux) -> Userspace (Busybox)
```

## Getting started Building
Lets start making our distro.

> This guide expectes you to know your way around a linux distro, specially in a terminal.

### 1 - Enviornment setup
In this guide we will use a Ubuntu enviornment. Hopefully any linux distro will work. However, Windows is not supported.

If you need a linux enviornment just use cloud vm like Gitpod, Github Codepspaces or Google Cloud Shell.

Testing of the image is OS agnostic and can run on any machine with qemu installed.

#### 1.1 - Installing dependencies
Run this in the shell to install all the required packages.
```bash
apt install bzip2 git vim make gcc libncurses-dev flex bison bc cpio libelf-dev libssl-dev syslinux dosfstools mtools grub2-common grub-pc-bin xorriso -y
```
##### 1.1.1 - List of dependencies
- bzip2
- git
- vim
- make
- gcc
- libncurses-dev
- flex
- bison
- bc
- cpio
- libelf-dev libssl-dev
- syslinux
- dosfstools
- mtools
- grub2-common
- grub-pc-bin
- xorriso

#### 1.2 - Setting up a boot files storage directory
It is recomended to create a directory to store all of your boot files that you will be creating all over the place.
```bash
mkdir boot-files
```
> **Note**: If you changed `boot-files` location, change any command to point to your `boot-files` directory.

#### 1.3 - Emulator for testing
This guide uses `qemu` for testing the os. To install it, go to the [qemu download page](https://www.qemu.org/download/) and follow the instructions for your os.

### 2 - Compiling the kernal
Lets now compile the linux kernal or the base sauce need to run.

#### 2.1 - Downloading the kernal
Clone the git repository [https://github.com/torvalds/linux.git (Github Mirror)](https://github.com/torvalds/linux), with `--depth 1` so that you don't download the entire history.
```bash
git clone --depth 1 https://github.com/torvalds/linux.git
```

#### 2.2 - Configuring the Kernal
cd into the Linux directory
```bash
cd linux
```
Next, lets configure for compiling. Lets open the config menu.
```bash
make menuconfig
```
Now just make sure the `64-bit kernal` option is selected, we don't need to touch anything else and we can move on.

Simply exit by selecting exit on the bottom bar and making sure to save the kernal configuration.

#### 2.3 - Compiling the kernal
Simply run `make`, to incerase the speed we can split the process into jobs to run on multiple cores. (use `lscpu` to find no of cores if you don't know)
```bash
make -j 8
```
It should take some time, so have a drink. 

Once its done copy the image from where the build command says it is to the boot file directory.

Output:
```bash
OBJCOPY arch/x86/boot/setup.bin
BUILD   arch/x86/boot/bzImage
Kernel: arch/x86/boot/bzImage is ready  (#1)
#          /\
#          |
#  What we are looking for
```
Command:

```bash
cp arch/x86/boot/bzImage ../boot-files
cd ..
```

### 3 - Compiling Busybox
Next the Busybox, the tools needed to interface with the os.

#### 3.1 - Downloading the busybox
Clone the git repository [https://git.busybox.net/busybox](https://git.busybox.net/busybox), with `--depth 1` so that you don't download the entire history.
```bash
git clone --depth 1 https://git.busybox.net/busybox
```

#### 3.2 - Configuring Busybox
cd into the busybox directory
```bash
cd busybox
```
Similar to the kernal, compiling config is done through a config menu.
```bash
make menuconfig
```
Now the only thing to change is set the build option to build static binary, the reason we slect this is to make building as simple as possible and not depend on external libraries.

1. Select settings in the top.
2. Scroll down till you find the `Build Options` category.
3. Press space to enable it.

Simply exit by selecting exit on the bottom bar and making sure to select yes to save the configuration.

#### 3.3 - Compiling busybox
Simply run `make`, to incerase the speed we can split the process into jobs to run on multiple cores. (use `lscpu` to find no of cores if you don't know)
```bash
make -j 8
```
It should take some time, so have a drink. 

#### 3.4 - Making an initramfs
Once its done compiling. Make a directory called `initramfs` in the `boot-files` directory.
```bash
cd ..
mkdir boot-files/initramfs
cd busybox
```
If you don't know what initramfs is, it is the inital file system the kernal loads after booting, and in this step we are putting busybox into that file system.

```bash
make CONFIG_PREFIX=../boot-files/initramfs install
```

### 4 - Setting up for a Bootable image
cd into the `initramfs` directory.
```bash
cd ..
cd boot-files/initramfs
``` 

#### 4.1 - Creating init file
Create a file here called `init` (`boot-files/initramfs/init`). And add the contents bellow:
```bash
#!/bin/sh

# Create a temporary RAM filesystem
mount -t tmpfs none /mnt
mkdir /mnt
mkdir /mnt/dev
mkdir /mnt/proc
mkdir /mnt/sys

# Mount essential filesystems
mount -t devtmpfs devtmpfs /mnt/dev
mount -t proc proc /mnt/proc
mount -t sysfs sysfs /mnt/sys

ln -s /mnt/proc /
ln -s /mnt/sys /

# Networking
ip link set eth0 up
udhcpc -i eth0

# Some defaults
dmesg -n 1

# Note: Can't Ctrl-C without cttyhack
# exec setsid cttyhack /bin/sh --rcfile /usr/.bashrc
exec setsid cttyhack /bin/sh
```
This file is basicly the first thing the kernal runs. The first line asks it to run using the shell, and the second line is asking it to open a shell for the user.

We also need to add execution permission to the `init` file.
```bash
chmod +x init
```

Also delete the `linuxrc` file in the `initramfs` directory.
```bash
rm linuxrc
```
#### 4.2 - Packaging the filesystem
Here we package the file system into an archive supported by the kernal.
```bash
find . | cpio -o -H newc > ../init.cpio.gz
```
If we break it down:
1. We find all the files in the `initramfs` direcotry
2. We then pipe all the files into the cpio command, telling it to create an archive in an archive format the kernal supports.
3. Finally save it to the parrent directory as `init.cpio.gz`

### 5 - Creating the boot file
Lets now create a bootable image. 

#### 5.1 - Creating a Disk
This creates an empty 64mb file filled with 0s to house our os and bootloader.
```bash
dd if=/dev/zero of=boot bs=1M count=64
```

#### 5.2 - Formating the image
We will be using the Fat filesytem as thats what syslinux supports. Here we are formating the boot image to fat.
```bash
mkfs -t fat boot
```
Next we will add the syslinux bootloader to the image.
```bash
syslinux boot
```

#### 5.3 - Adding a bootloader config
Create a file here called `syslinux.cfg` (`boot-files/syslinux.cfg`). And add the contents bellow:
```
DEFAULT linux
LABEL linux
 SAY Now booting the kernel with initramfs from SYSLINUX...
 KERNEL bzImage
 APPEND initrd=init.cpio.gz root=/dev/ram0
```
This file is the configuration file that the syslinux bootloader loads on boot and configures the enviornment it should be booted in. Here we are provide the kernal image and the initramfs it should boot with. 

#### 5.4 - Copying the kernal and initramfs into the image
Copy the `bzimage` (kernal) and `init.cpio.gz` into the image with `mcopy`.
```bash
mcopy -i boot bzImage ::bzImage
mcopy -i boot init.cpio.gz ::init.cpio.gz
mcopy -i boot syslinux.cfg ::syslinux.cfg
```
And now your image is ready to roll.

### 6 - Testing the image
Using qemu lets test the image.
```shell
qemu-system-x86_64 -drive file=boot,format=raw -m 2G
```
Note: replace `boot` with whatever you named your file.

~~Then a window should pop up asking for a boot. Type in the following: `/bzImage -initrd=/init.cpio.gz`~~ (Only applicable if no syslinux config)

### 7 - Making an ISO
To make it bootable from a storage medium, we need to make an ISO. Also this time we will be switching from syslinux to grub for the bootloader as it provides simple tooling to create an iso.

#### 7.1 - Settting up Directories
Create a directory called `iso` in the `boot-files` directory. Within that create a `boot` directory and within that `grub`.
```bash
mkdir ./boot-files/iso
mkdir ./boot-files/iso/boot
mkdir ./boot-files/iso/boot/grub
```

#### 7.2 - Moving the required Files
Copy the `bzImage` and `init.cpio.gz` into the `boot` directory in the `iso` directory.
```bash
cp ./boot-files/bzImage ./boot-files/iso/boot
cp ./boot-files/init.cpio.gz ./boot-files/iso/boot
```

#### 7.3 - Adding a bootloader config
Create a file here called `grub.cfg` in the `grub` directory in the `boot` directory (`boot-files/iso/boot/grub/grub.cfg`). And add the contents bellow:
```
set default=0
set timeout=10
menuentry 'yourOs' --class os {
  insmod gzio
  insmod part_msdos
  linux /boot/bzImage
  initrd /boot/init.cpio.gz
}
```

#### 7.4 - Making the ISO
Using grub-mkrescue to build the ISO.
```bash
grub-mkrescue -o ./boot-files/boot.iso ./boot-files/iso
```
This should create a `boot.iso` file in the `boot-files` directory.

Now your distro is ready to boot on real hardware.

### 8 - Testing the ISO
Lets test the ISO in an emulator then on a real system.
```shell
qemu-system-x86_64 -cdrom boot.iso -m 2G
```
Note: replace `boot.iso` with whatever you named your iso.