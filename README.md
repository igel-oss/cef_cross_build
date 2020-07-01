# CEF ozone/wayland Cross Build for Renesas R-Car

This branch is TEST.

## Reference

- CEF ozone/wayland
  - https://bitbucket.org/chromiumembedded/cef/pull-requests/288/wip-add-better-ozone-wayland-x11-support/diff
  - https://bitbucket.org/chromiumembedded/cef/issues/2804/ozone-wayland-x11-support
- Build CEF
  - https://bitbucket.org/chromiumembedded/cef/wiki/MasterBuildQuickStart.md#markdown-header-linux-setup

## Environment

The purpose is for the sample program "cefsimple" included in CEF to run in Renesas Yocto BSP on R-Car board. This procedure was tested on R-CarH3.
(https://bitbucket.org/chromiumembedded/cef/wiki/MasterBuildQuickStart.md#markdown-header-linux-setup )

## Get CEF code
Download CEF code to `/path/to/cef`, and checkout wayland_support branch.

```bash
$ mkdir -p /path/to/cef
$ cd /path/to/cef
$ git clone https://bitbucket.org/msisov/cef
$ cd cef
$ git checkout origin/wayland_support
```

As of 2020.05.26, wayland_support branch HEAD is `bbc875c6c8b5aecc176141a7a88002631ee1bad2`.

## Create build environment

Get cef_cross_build git repository for creating docker image.

```bash
$ cd path/to/cef
$ git clone https://github.com/igel-oss/cef_cross_build.git
```

Checkout ozone-wayland-test branch.

```bash
$ cd path/to/cef/cef_cross_build
$ git checkout ozone-wayland-test
```

Copy the Renesas Yocto BSP toolchain SDK to docker directroy. See the Yocto / BSP documentation for details on building the SDK.

```bash
$ cp poky-glibc-x86_64-core-image-weston-sdk-aarch64-toolchain-2.4.3 cef_cross_build/docker/
```

Replace the poky version of toolchain as appropriate. See the README in the docker directory for more details.

Create docker image.

```bash
$ cd cef_cross_build/docker
$ docker build -t cef_build:18.04 ./
```

Specify poky version by --build-arg option if the toolchain poky version isn't "2.4.3", for example:

```bash
$ docker build --build-arg poky="3.0" -t cef_build:18.04 ./
```

## Build
CEF is designed to patch and build Chromium. Run automate-git.py to prepare building Chromium. It is easy to work by copying automate-git.py to /path/to/cef.

```bash
$ cd /path/to/cef/
$ cp cef/tools/automate/automate-git.py ./
```

The automate-git.py has options to specify CEF and chromium checkout points. Use --checkout option to specify the CEF checkout point and --chromium-checkout option to specify the chromium checkout point. When -chromium-checkout is omitted, the latest available chromium is used (as of 2019.07.29, chromium ver. 76.0.3809.0 is selected).

This build procedure has been tested on the wayland_support branch of msisov/cef repository.

```bash
$ cd /path/to/cef
$ python ./automate-git.py --download-dir=. --no-distrib --no-build --checkout=bbc875c6c8b5aecc176141a7a88002631ee1bad2 --url=https://bitbucket.org/msisov/cef
```

Wait a very long time for the Chromium source code to be downloaded.

Create symbolic link: `chromium/src/build/linux/debian_sid_arm64-sysroot` => `/opt/poky/[poky version]/sysroots/aarch64-poky-linux`, because it is necessary that the path of sysroot for arm64 is chromium/src/build/linux/debian_sid_arm64-sysroot.

```bash
$ cd /path/to/cef/chromium/src/build/linux
$ ln -s /opt/poky/2.4.3/sysroots/aarch64-poky-linux debian_sid_arm64-sysroot
```

Build in docker container.

```bash
$ cd /path/to/cef
$ docker run -u $(id -u $USER):$(id -g $USER) -it --rm -v $(pwd):$(pwd) -w $(pwd) -e GYP_DEFINES -e GN_DEFINES cef_build:18.04
docker$ cd depot_tools
docker$ export PATH=`pwd`:$PATH
docker$ cd ../chromium/src/cef
docker$ export GYP_DEFINES=target_arch=arm64
docker$ export GN_DEFINES="is_official_build=true use_sysroot=true use_allocator=none symbol_level=1 use_cups=false use_gnome_keyring=false enable_remoting=false enable_nacl=false use_kerberos=false use_gtk=false treat_warnings_as_errors=false ozone_platform_wayland=true ozone_platform_x11=true ozone_platform=wayland use_ozone=true use_glib=true use_aura=true ozone_auto_platforms=false dcheck_always_on=false use_xkbcommon=true use_system_minigbm=true use_system_libdrm=true"
docker$ ./cef_create_projects.sh
docker$ cd ../
docker$ ninja -j16 -C out/Release_GN_arm64/ cefsimple
```

* Note: If we don't specify use_system_minigbm=true, chromium use minigbm which  chromium has. Since minigbm don't support rcar-du, gbm device initialization is failed. In this case, we cannot use dmabuf in chromium because chromium uses shm buffer.

## Running


Copy the following files in chromium/src/out/Release_GN_arm64/ to rootfs (ex: /home/root/cef/).

```bash
cefsimple
libcef.so
icudtl.dat
*.pak
*.bin
locales
pyproto
resources
swiftshader
```

Specify date, and run `cefsimple` with `--use-views` options.

```bash
rcar# date -s [today]
rcar# cd ~/cef
rcar# ./cefsimple --no-sandbox --use-views
```

Google Web Site is shown. WebGL also works (https://webglsamples.org/aquarium/aquarium.html).
