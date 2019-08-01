This README describes how to build and run the Chromium blink_tests using the 
CEF source tree on the Renesas R-Car platform.

## Create build environment

Refer to "Create build environment" section of the [main README](../README.md).

## Build

The following assumes that the source/build directories have been used to successfully compile cefsimple at least once.
Please follow the instructions in the "Build" section of the [main README](../README.md) if you have not yet done so.

Apply a patch into chromium to fix compiling errors, and build blink_tests and imagediff. The patch is located in the `blinktests/for_chromium` directory of cef_cross_build git repository.

```bash
$ cd /path/to/cef/chromium/src/
$ patch -p1 < /path/to/cef/cef_cross_build/blinktests/for_chromium/0001-fix-build-error-for-blink_tests.patch

docker$ ninja -j16 -C out/Release_GN_arm64/ blink_tests image_diff
```

Create an installation tarball, blink_tests.tar.gz using the `make_blink_test_tarball.sh` script included in the cef_cross_build repository.  This will be used to install all necessary blink_tests files to the test environment.

```bash
$ cd /path/to/cef/cef_cross_build/blinktests/
$ ./make_blink_test_tarball.sh /path/to/cef/chromium/src
```

## Create test environment (rootfs)

In order to run blink_tests from the target platform, several additional packages such as apache2 and php are necessary. These packages  are not included in Renesas Yocto BSP standard installation, so you must modify the config and recipe of Yocto, and rebuild the rootfs.

### Update config

First, append the following to conf/bblayers.conf.

```bash
BBLAYERS =+ " \
 ${TOPDIR}/../meta-openembedded/meta-perl \
 ${TOPDIR}/../meta-cpan \
 ${TOPDIR}/../meta-openembedded/meta-webserver \
 ${TOPDIR}/../meta-cloud-services \
 ${TOPDIR}/../meta-cloud-services/meta-openstack \
 ${TOPDIR}/../meta-openembedded/meta-python  "
```

Get meta-cloud from [git://git.yoctoproject.org/meta-cloud-services and meta-cpan]( git://git.yoctoproject.org/meta-cloud-services) from [https://github.com/rehsack/meta-cpan.git](https://github.com/rehsack/meta-cpan.git), and change the branch to match your Yocto version (most recently tested: thud).

```bash
$ cd /path/to/yocto-bsp/
$ git clone git://git.yoctoproject.org/meta-cloud-services
$ git clone https://github.com/rehsack/meta-cpan.git
$ cd meta-cloud-services
$ git checkout origin/<sumo/thud/warrior>
$ cd ../meta-cpan
$ git checkout origin/<sumo/thud/warrior>
```

Next, append the following to conf/local.conf.

```bash
IMAGE_INSTALL_append = " \
                        python-virtualenv \
                        apache2 \
                        php \
                        php-modphp \
                        git \
                        libcgi-perl \
                        perl-module-if \
                        perl-module-deprecate \
                        perl-module-io-socket \
                        perl-module-exporter \
                        perl-module-utf8 \
                        perl-module-encode \
                        perl-module-time-hires \
                        perl-module-file-stat \
                        perl-module-mime-base64 \
                        http-date-perl "

PACKAGECONFIG_append_pn-php = " apache2"
EXTRA_OECONF_append_pn-apache2 = " --enable-asis --with-mpm='prefork'"
EXTRA_OECONF_append_pn-libxml2 = " --with-icu"
DEPENDS_append_pn-libxml2 = " icu"
```

### Update recipes

Some older branches of meta-cloud-server require a minor update to the
build recipe. 
Fix python-virtualenv recipe in meta-cloud-service as follows:

```bash
diff --git a/meta-openstack/recipes-devtools/python/python-virtualenv_1.11.4.bb
index c2fb657..4d51bfa 100644
--- a/meta-openstack/recipes-devtools/python/python-virtualenv_1.11.4.bb
+++ b/meta-openstack/recipes-devtools/python/python-virtualenv_1.11.4.bb
@@ -7,7 +7,7 @@ LIC_FILES_CHKSUM = "file://LICENSE.txt;md5=53df9f8889d6a5fba83f4
 PR = "r0"

 SRCNAME = "virtualenv"
-SRC_URI = "http://pypi.python.org/packages/source/v/${SRCNAME}/${SRCNAME}-${PV}
+SRC_URI = "https://pypi.python.org/packages/source/v/${SRCNAME}/${SRCNAME}-${PV}
```

### Build

Build yocto image with bitbake and install on the target system as normal.

```bash
$ cd /path/to/yocto-bsp/
$ . poky/oe-init-build-env
$ bitbake core-image-weston
```

## Test environment setup

blink_tests will not run as the root user, and the BSP environment does not
provide a full mulit-user configuration for use with wayland by default. 
The following describes the minimum system settings to run blink_tests.

### Add test user
Create test user and add the user to video group because blink_tests cannot be run as root user.

```bash
rcar# useradd -a -m test
```

Add the user to video group if the user exists already and the user doesn't belong to video group.

```bash
rcar# usermod -aG video test
```

### Give test user access to necessary wayland directories

Change permissions of `/run/user/0` and `/run/user/0/wayland-0` to allow test user to communicate with wayland server.

```bash
rcar# chmod 777 /run/user/0
rcar# chmod 777 /run/user/0/wayland-0
```

Set the current system date.

```bash
rcar# date -s [today]
```

Copy and extract the `blink_tests.tar.gz` created during the blink_tests build to the test user directory on the test environment.

```bash
rcar# su test
rcar$ cd ~
rcar$ tar xf blink_tests.tar.gz
```
### Install google depot_tools

Download depot_tools to rootfs according to https://chromium.googlesource.com/chromium/src/+/master/docs/linux_build_instructions.md#install.

### Environment variables

Add depot_tools directory to the PATH environment variable.

Set the full path location of apache config file `yocto-httpd-2.4.conf` in the WEBKIT_HTTP_SERVER_CONF_PATH environment variable. 

```bash
rcar$ setenv PATH="${PATH}:/home/test/depot_tools"
rcar$ setenv WEBKIT_HTTP_SERVER_CONF_PATH="/home/test/yocto-httpd-2.4.conf"
```

## Running 

The full test suite can be run with the following command line:

```bash
rcar$ ./third_party/blink/tools/run_web_tests.py --additional-driver-flag="--ozone-platform=wayland" --additional-driver-flag="--use-gl=egl" --additional-driver-flag="--in-process-gpu" --disable-breakpad --no-xvfb -j 2
```

