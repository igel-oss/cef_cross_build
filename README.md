# CEF Cross Build for Renesas R-Car

This repository tags:
* cef-3770 - for CEF ver. 3770
* cef-3809 - for CEF ver. 3809

## Environment

The purpose is for the sample program "cefsimple" included in CEF to run in Renesas Yocto BSP on R-Car board. This procedure was tested on R-CarH3.
(https://bitbucket.org/chromiumembedded/cef/wiki/MasterBuildQuickStart.md#markdown-header-linux-setup )

## Get building tool and code
Get building tool and CEF code, and save to `/path/to/cef`.

```bash
$ mkdir -p /path/to/cef
$ cd /path/to/cef
$ git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
$ git clone https://bitbucket.org/chromiumembedded/cef.git
```

As of 2019.07.29, CEF master HEAD is `ccb06ce3cb70cdd37fafbf78b12a14b624183ac4`.

Note: Since arm64 support patch has only recently been merged into the master branch, the patch may not yet be included in the stable branch.

## Create build environment

Get cef_cross_build git repository for creating docker image.

```bash
$ cd path/to/cef
$ git clone https://github.com/igel-oss/cef_cross_build.git
```

If CEF version is latest, use master HEAD, otherwise, checkout according to the CEF version.

```bash
$ cd path/to/cef/cef_cross_build
$ git checkout cef-[Version]
```

Copy the Renesas Yocto BSP toolchain SDK to docker directroy. See the Yocto / BSP documentation for details on building the SDK.

```bash
$ cp poky-glibc-x86_64-core-image-weston-sdk-aarch64-toolchain-2.4.3 cef_cross_build/docker/
```

Replace the poky version of toolchain as appropriate. See the README in the docker directory for more details.

Create docker image.

```bash
$ cd cef_cross_build/docker
$ docker build -t cef_build:16.04 ./
```

Specify poky version by --build-arg option if the toolchain poky version isn't "2.4.3", for example:

```bash
$ docker build --build-arg poky="2.6.2" -t cef_build:16.04 ./
```

## Build
CEF is designed to patch and build Chromium. Run automate-git.py to prepare building Chromium. It is easy to work by copying automate-git.py to /path/to/cef.

```bash
$ cd /path/to/cef/
$ cp cef/tools/automate/automate-git.py ./
```

The automate-git.py has options to specify CEF and chromium checkout points. Use --checkout option to specify the CEF checkout point and --chromium-checkout option to specify the chromium checkout point. When -chromium-checkout is omitted, the latest available chromium is used (as of 2019.07.29, chromium ver. 76.0.3809.0 is selected).

This build procedure has been tested on the master branch (Commit ID: `ccb06ce3cb70cdd37fafbf78b12a14b624183ac4`).

```bash
$ cd /path/to/cef
$ export GYP_DEFINES=target_arch=arm64
$ export GN_DEFINES="is_official_build=true use_sysroot=true use_allocator=none symbol_level=1 use_cups=false use_gnome_keyring=false enable_remoting=false enable_nacl=false use_kerberos=false use_gtk=false treat_warnings_as_errors=false ozone_platform_wayland=true ozone_platform=wayland use_ozone=true use_aura=true ozone_auto_platforms=false dcheck_always_on=false use_xkbcommon=true use_system_minigbm=true use_system_libdrm=true"
$ python ./automate-git.py --download-dir=. --no-distrib --no-build
```

Wait a very long time for the Chromium source code to be downloaded.

Create symbolic link: `chromium/src/build/linux/debian_sid_arm64-sysroot` => `/opt/poky/[poky version]/sysroots/aarch64-poky-linux`, because it is necessary that the path of sysroot for arm64 is chromium/src/build/linux/debian_sid_arm64-sysroot.

```bash
$ cd /path/to/cef/chromium/src/build/linux
$ ln -s /opt/poky/2.4.3/sysroots/aarch64-poky-linux debian_sid_arm64-sysroot
```

Build in docker container. However, need to apply the patch "0001-Fix-compile-error-for-ver.-3809.patch" in cef_cross_build git repository to chromium as of 2019.07.29. (If CEF version is 3770, this patch is unnecessary.)

```bash
$ cd /path/to/cef
$ docker run -u $(id -u $USER):$(id -g $USER) -it --rm -v $(pwd):$(pwd) -w $(pwd) -e GYP_DEFINES -e GN_DEFINES cef_build:16.04
docker$ cd depot_tools
docker$ export PATH=`pwd`:$PATH
docker$ cd ../chromium/src/cef
docker$ ./cef_create_projects.sh
docker$ cd ../

$ cd /path/to/cef/chromium/src
$ patch -p1 < /path/to/cef/cef_cross_build/0001-Fix-compile-error-for-ver.-3809.patch

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
etc
resources
swiftshader
```

Specify date, and run `cefsimple` with `--mus` and `--use-views` options.

```bash
rcar# date -s [today]
rcar# cd ~/cef
rcar# ./cefsimple --no-sandbox --mus --use-views
```

Google Web Site is shown. WebGL also works (https://webglsamples.org/aquarium/aquarium.html).

## Appendix
### Build for X11

Set environment value for X11, and exec automate-git.py.

```bash
$ export GYP_DEFINES=target_arch=arm64
$ export GN_DEFINES="is_official_build=true use_sysroot=true use_allocator=none symbol_level=1 use_cups=false use_gnome_keyring=false enable_remoting=false enable_nacl=false use_kerberos=false use_gtk=false"
$ python ./automate-git.py --download-dir=. --no-distrib --no-build
```

libXss is needed for Chromium building for X11, but there is not libXss in Yocto sysroot. Copy libXss.* from debian sysroot for arm64. There is sysroot in docker container, and sysroot path is `/opt/poky/[poky version]/sysroots/aarch64-poky-linux`.

Since it is necessary that the path of sysroot for arm64 is `chromium/src/build/linux/debian_sid_arm64-sysroot`, remove or rename debian_sid_arm64-sysroot, and create symbolic link: `chromium/src/build/linux/debian_sid_arm64-sysroot` => `/opt/poky/[poky version]/sysroots/aarch64-poky-linux`.

```bash
$ cd /path/to/cef/chromium/src/build/linux/
$ mv debian_sid_arm64-sysroot debian_sid_arm64-sysroot.org
$ ln -s /opt/poky/2.4.3/sysroots/aarch64-poky-linux chromium/src/build/linux/debian_sid_arm64-sysroot
```

Work from here is done in the docker container.

```bash
$ cd /path/to/cef
$ sudo docker run -u $(id -u $USER):$(id -g $USER) -it --rm -v $(pwd):$(pwd) -w $(pwd) -e GYP_DEFINES -e GN_DEFINES cef_build:16.04
docker$ cd depot_tools
docker$ export PATH=`pwd`:$PATH
docker$ cd ../chromium/src/cef
docker$ ./cef_create_projects.sh
docker$ cd ../
docker$ ninja -j16 -C out/Release_GN_arm64/ cefsimple
```

Create cefsimple binary in chromium/src/out/Release_GN_arm64/.

### Running (X11)
Copy the following files in chromium/src/out/Release_GN_arm64/ to rootfs (ex: /home/root/cef/).

```bash
*.pak
*.bin
cefsimple
icudtl.dat
libVkICD_mock_icd.so
libVkLayer_core_validation.so
libVkLayer_object_tracker.so
libVkLayer_parameter_validation.so
libVkLayer_threading.so
libVkLayer_unique_objects.so
libcef.so
locales/*.pak
pyproto/
resources/
swiftshader/libEGL.so
swiftshader/libGLESv2.so
```

And, copy libXss from /path/to/yocto-sysroot/usr/lib/ to rootfs:/usr/lib/.

Since built cefsimple runs on X11, xwayland is required. So Restart weston with xwayland. Chromium will not work properly if the system dates are off by significant. Furthermore, set DISPLAY=:0 for running cefsimple.

```bash
rcar# systemctl stop weston
rcar# date -s [today]
rcar# export DISPLAY=:0
rcar# weston --tty=2 -Bdrm-backend.so --xwayland -i0 &
rcar# cd ~/cef/
rcar# ./cefsimple --no-sandbox
```

* Note 1: weston needs to specify drm-backend explicitly to try to run x11 backend by default if exported DISPLAY environment variable.
* Note 2: Crash weston if weston version is 5.0.0 or 6.0.0. This issue fixes following patch (merged to master):

```
commit 6f9db6c4a16d853bbc5889ad5ff0d9c75e21d69c
Author: Tomohito Esaki <etom@igel.co.jp>
Date:   Mon Apr 1 17:51:35 2019 +0900

    cairo-util: Don't set title string to Pango layout if the title is NULL
```
