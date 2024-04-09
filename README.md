# Nimbu
A minimal linux distro from scratch. Compiled by a single script. Built with the latest (stable) linux kernal, busybox for the userspace and Nano X11 for a Graphics backend.

Also ships with [QuickJS](https://bellard.org/quickjs/) (js interpreter), [cosmopolitan c](https://cosmo.zip/) (cross platform c compiler), a copy [conways game of life](https://justine.lol/apelife/) and the source for a copy of [chess](https://github.com/hsnborn22/C-HESS) ([distro specific fork](https://github.com/imagineeeinc/c-hess)) you have to compile your self.

## Building
Make the build script executable
```bash
chmod +x build.sh
```

- Run the script, to build everything.
  ```bash
  # Everything
  ./build.sh
  ```

- If you want to build seprate parts then:
  ```bash
  # Keranl Only
  ./build.sh kernal
  # Busybox Only
  ./build.sh busybox
    # Graphical Enviornment Only
  ./build.sh gui
  # Image Only
  ./build.sh image
  ```

- To build the iso, make sure you have compiled everything and made an image (so the required files has been made). Then run:
  ```bash
  ./build.sh iso
  ```

## Making a distro your self.
There is a fully writen guide on building your distro, [here (making a linux distro guide.md)](making%20a%20linux%20distro%20guide.md).