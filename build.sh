# Recomened to run on a Ubuntu enviornment
# Install these packages using the command:
# apt install bzip2 git vim make gcc libtool libpng-dev libfreetype-dev libxinerama-dev g++ libncurses-dev flex bison bc cpio libelf-dev autoconf libssl-dev syslinux dosfstools mtools grub2-common grub-pc-bin xorriso -y

function kernal() {
  echo "Compiling kernal"
  if [ -d "./linux/.git" ]; then
    cd linux
    git pull
  else
    git clone --depth 1 https://github.com/torvalds/linux.git
    cd linux
  fi
  cp ../src/kernal.config ./.config
  # make menuconfig
  echo "Done configuring"
  make -j "$(nproc)"
  echo "Done compiling kernal"
  cp arch/x86/boot/bzImage ../boot-files
  cd ..
}
function busybox-compile() {
  echo "Compiling busybox"
  if [ -d "./busybox/.git" ]; then
    cd busybox
    git pull
  else
    #git clone --depth 1 https://git.busybox.net/busybox
    cd busybox
  fi
  cp ../src/busybox.config ./.config
  # make menuconfig
  ln -s /usr/lib ../boot-files/initramfs/usr/lib
  ln -s /usr/include ../boot-files/initramfs/usr/include
  echo "Done configuring"
  make -j "$(nproc)"
  echo "Done compiling busybox"
  if [ -d "./boot-files/initramfs" ]; then
    echo "initramfs directory exist"
  else
    mkdir -p ../boot-files/initramfs
  fi
  mkdir -p BUSYBOX
  make CONFIG_PREFIX=./BUSYBOX install
  cp -rn BUSYBOX/* ../boot-files/initramfs
  cd ..
}
function glibc-compile() {
  echo "Compiling glibc"
  if [ -d "./glibc/.git" ]; then
    cd glibc
    git pull
  else
    git clone --depth 1 	https://sourceware.org/git/glibc.git
    cd glibc
  fi
  mkdir -p build
  mkdir GLIBC

  cd build
  ../configure --prefix=
  make -j "$(nproc)"

  make install DESTDIR=../GLIBC

  cd ..
  if [ -d "../boot-files/initramfs" ]; then
    echo "initramfs directory exist"
  else
    mkdir -p ../boot-files/initramfs
  fi
  mkdir -p ../boot-files/initramfs/usr
  cp -r ./GLIBC/* ../boot-files/initramfs
  cp -r ./GLIBC/* ../boot-files/initramfs

  cd ..
  cp -r ./GLIBC/include/* ./boot-files/initramfs/include
  cp -r ./GLIBC/lib/* ./boot-files/initramfs/lib

  cp -rn ./linux/include/* ./boot-files/initramfs/include
  cp -rn ./linux/lib/* ./boot-files/initramfs/lib
}
function build-image() {
  echo "Installing Applications"
  if [ -d "./cosmocc" ]; then
    echo "cosmocc exist"
  else
    mkdir -p cosmocc
    cd cosmocc
    wget -q https://cosmo.zip/pub/cosmocc/cosmocc.zip
    unzip cosmocc.zip
    cd ..
  fi
  if [ -d "./cosmo-include" ]; then
    cd cosmo-include
    git pull
    cd ../
  else
    git clone https://github.com/fabriziobertocci/cosmo-include.git
  fi

  echo "Installing: cosmocc"
  cp -r ./cosmocc ./boot-files/initramfs/usr
  cp -R ./cosmo-include ./boot-files/initramfs/cosmo

  echo "Installing: quickjs"
  wget -q -O qjs-cosmo.zip https://bellard.org/quickjs/binary_releases/quickjs-cosmo-2024-01-13.zip
  unzip -p qjs-cosmo.zip qjs > ./boot-files/initramfs/usr/qjs
  rm -f qjs-cosmo.zip

  echo "Installing: chess"
  if [ -d "./c-hess" ]; then
    echo "chess exist"
    cd c-hess
    git pull
    cd ../
  else
    git clone https://github.com/imagineeeinc/c-hess.git
  fi
  mkdir -p ./boot-files/initramfs/usr/chess
  cp -a ./c-hess/code ./boot-files/initramfs/usr/chess
  cp -a ./c-hess/README.md ./boot-files/initramfs/usr/chess

  echo "Installing: Apelife"
  curl https://justine.lol/apelife/spacefiller.rle > ./boot-files/initramfs/usr/spacefiller.rle
  curl https://justine.lol/apelife/apelife-latest.com > ./boot-files/initramfs/usr/apelife
  chmod +x ./boot-files/initramfs/usr/apelife

  echo "Building image"
  cd boot-files/initramfs
  mkdir -p var etc root tmp dev proc

  local cur_time="$(date +%Y.%m.%d\(%H:%M\))"

  cp -a -r ../../src/fs/. ./
  chmod +x init
  mkdir -p ./dev ./proc ./sys
  ln -s ./lib ./lib64
  rm linuxrc
  echo "$cur_time" > version
  find . | cpio -o -H newc | gzip > ../init.cpio.gz

  local image_name=${1:-"boot.img"}

  cd ..
  # dd if=/dev/zero of="$image_name" bs=1M count=384
  # mkfs -t fat "$image_name"
  # syslinux "$image_name"
  rm "$image_name"
  truncate -s 2500M "$image_name"
  mkfs -t fat "$image_name"
  syslinux "$image_name"

  cp ../src/syslinux.cfg ./
  mcopy -i "$image_name" bzImage ::bzImage
  # mcopy -i "$image_name" init.cpio.gz ::init.cpio.gz
  mcopy -i "$image_name" syslinux.cfg ::syslinux.cfg
  cd initramfs
  for f in * ; do mcopy -sp -i ../"$image_name" "$f" ::"$f" ; done
  echo "Done Building image. Located at: 'boot-file/$image_name'"
}
# truncate -s 1536MB boot.img
# mkfs -t fat boot.img
# syslinux boot.img
# cd initramfs
# for f in * ; do mcopy -sp -i ../boot.img "$f" ::"$f" ; done

function gui-compile() {
  # TODO: Build gui with nano x and pixil oe
  if [ -d "./microwindows/.git" ]; then
    cd microwindows
    git pull
  else
    git clone --depth 1 https://github.com/ghaerr/microwindows
    cd microwindows
  fi
  cd src
  # cp Configs/config.linux-fb config
  cp ../../src/microwindows.config config
  echo "Done configuring"

  # Build
  make -j 16

  # Build helloword gui
  make install
  cd ../..
  gcc ./src/fs/usr/hello_gui.c -lNX11 -lnano-X -I ./microwindows/src/nx11/X11-local/
  mv ./a.out ./boot-files/initramfs/usr
  echo "built hello world gui"

  # Copy Shared Lib
  cd ./microwindows/src/bin
  mkdir -p ../../../boot-files/initramfs/lib/x86_64-linux-gnu
  mkdir -p ../../../boot-files/initramfs/lib64
  ldd nano-X | awk 'NF == 4 { system("cp -f " $3 " ../../../boot-files/initramfs/lib/x86_64-linux-gnu") }'
  cp -f /lib64/ld-linux-x86-64.so.2 ../../../boot-files/initramfs/lib64

  # Copy binary
  cd ..
  cp -a -r ./bin ../../boot-files/initramfs/nanox
  cp -a ./runapp ../../boot-files/initramfs/nanox
  echo "Installed shared libs and binary"

  cd ../..
}
function build-iso() {
  mkdir -p ./boot-files/iso
  mkdir -p ./boot-files/iso/boot
  mkdir -p ./boot-files/iso/boot/grub

  cp ./boot-files/bzImage ./boot-files/iso/boot
  cp ./boot-files/init.cpio.gz ./boot-files/iso/boot
  cp ./src/grub.cfg ./boot-files/iso/boot/grub

  local image_name=${1:-"nimbu"}

  grub-mkrescue -o ./boot-files/"$image_name".iso ./boot-files/iso

  # Using it in qemu:
  # qemu-system-x86_64 -cdrom nimbu.iso -m 2G -net nic,model=virtio -net user
}

if [ -d "./boot-files" ]; then
  echo "Boot Files exist"
else
  mkdir -p "boot-files"
fi

if [ "$1" = "kernal" ]; then
  kernal
elif [ "$1" = "libc" ]; then
  glibc-compile
elif [ "$1" = "busybox" ]; then
  busybox-compile
elif [ "$1" = "gui" ]; then
  gui-compile
elif [ "$1" = "image" ]; then
  build-image "$2"
elif [ "$1" = "iso" ]; then
  build-iso "$2"
else
  echo "Compiling kernal, busy box and x server & building image and iso"
  kernal
  glibc-compile
  busybox-compile
  gui-build
  build-image
  build-iso
fi
