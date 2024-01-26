# Recomened to run on a Ubuntu enviornment
# Install these packages using the command:
# apt install bzip2 git vim make gcc libncurses-dev flex bison bc cpio libelf-dev libssl-dev syslinux dosfstools mtools grub2-common grub-pc-bin xorriso -y

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
    mkdir -p ../boot-files/initramfs
  fi
  make CONFIG_PREFIX=../boot-files/initramfs install
  cd ..
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

  echo "Installing: cosmocc"
  cp -r ./cosmocc ./boot-files/initramfs/usr

  echo "Installing: quickjs"
  wget -q -O qjs-cosmo.zip https://bellard.org/quickjs/binary_releases/quickjs-cosmo-2024-01-13.zip
  unzip -p qjs-cosmo.zip qjs > ./boot-files/initramfs/usr/qjs
  rm -f qjs-cosmo.zip

  echo "Installing: Apelife"
  curl https://justine.lol/apelife/spacefiller.rle > ./boot-files/initramfs/usr/spacefiller.rle
  curl https://justine.lol/apelife/apelife-latest.com > ./boot-files/initramfs/usr/apelife
  chmod +x ./boot-files/initramfs/usr/apelife

  echo "Building image"
  cd boot-files/initramfs

  local cur_time="$(date +%Y.%m.%d\(%H:%M\))"

  cp -a -r ../../src/fs/. ./
  chmod +x init
  rm linuxrc
  echo "$cur_time" > version
  find . | cpio -o -H newc | gzip > ../init.cpio.gz

  local image_name=${1:-"boot"}

  cd ..
  dd if=/dev/zero of="$image_name" bs=1M count=640
  mkfs -t fat "$image_name"
  syslinux "$image_name"

  cp ../src/syslinux.cfg ./
  mcopy -i "$image_name" bzImage ::bzImage
  mcopy -i "$image_name" init.cpio.gz ::init.cpio.gz
  mcopy -i "$image_name" syslinux.cfg ::syslinux.cfg
  echo "Done Building image. Located at: 'boot-file/$image_name'."
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
  qemu-system-x86_64 -cdrom nimbu.iso -m 2G -net nic,model=virtio -net user
}

if [ -d "./boot-files" ]; then
  echo "Boot Files exist"
else
  mkdir -p "boot-files"
fi

if [ "$1" = "kernal" ]; then
  kernal
elif [ "$1" = "busybox" ]; then
  busybox-compile
elif [ "$1" = "image" ]; then
  build-image "$2"
elif [ "$1" = "iso" ]; then
  build-iso "$2"
else
  echo "Compiling kernal and busy box and building image"
  kernal
  busybox-compile
  build-image
fi