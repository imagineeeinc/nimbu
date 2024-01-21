# Recomened to run on a Ubuntu enviornment
# Install these packages using the command:
# apt install bzip2 git vim make gcc libncurses-dev flex bison bc cpio libelf-dev libssl-dev syslinux dosfstools mtools -y

function kernal() {
  echo "Compiling kernal"
  if [ -d "./linux/.git" ]; then
    cd linux
    git pull
  else
    git clone --depth 1 https://gitxhub.com/torvalds/linux.git
    cd linux
  fi
  make menuconfig
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
    git clone --depth 1 https://git.busybox.net/busybox
    cd busybox
  fi
  make menuconfig
  echo "Done configuring"
  make -j "$(nproc)"
  echo "Done compiling busybox"
  if [ -d "./boot-files" ]; then
    echo "initramfs directory exist"
  else
    mkdir ../boot-files/initramfs
  fi
  make CONFIG_PREFIX=../boot-files/initramfs install
  cd ..
}
function build-image() {
  echo "Building image"
  cd boot-files/initramfs

  cp ../../src/init ./
  chmod +x init
  rm linuxrc
  find . | cpio -o -H newc > ../init.cpio

  cd ..
  dd if=/dev/zero of=boot bs=1M count=64
  mkfs -t fat boot
  syslinux boot

  cp ../src/syslinux.cfg ./
  mcopy -i boot bzImage ::bzImage
  mcopy -i boot init.cpio ::init.cpio
  mcopy -i boot syslinux.cfg ::syslinux.cfg
  echo "Done Building image. Located at: 'boot-file/boot'."
}

if [ -d "./boot-files" ]; then
  echo "Boot Files exist"
else
  mkdir "boot-files"
fi

if [ "$1" = "kernal" ]; then
  kernal
elif [ "$1" = "busybox" ]; then
  busybox-compile
elif [ "$1" = "image" ]; then
  build-image
else
  echo "Compiling kernal and busy box and building image"
  kernal
  busybox-compile
  build-image
fi