#! /usr/bin/bash

# install pipewire
cd /tmp
if [ $1 != "2.4.3" ]; then
    echo "change 2.4.3 to $1"
    sed -i -e s/2.4.3/$1/ meson.cross
fi
git clone https://github.com/PipeWire/pipewire.git
mv meson.cross pipewire/
cd pipewire
mkdir build
. /opt/poky/$1/environment-setup-aarch64-poky-linux
unset CC CXX
meson build --cross-file meson.cross --prefix /usr
ninja -C build
DESTDIR=$SDKTARGETSYSROOT ninja -C build/ install
cd /tmp
rm -rf pipewire

#update libgbm
GBM_VERSION=$(PKG_CONFIG_PATH=/opt/poky/$1/sysroots/aarch64-poky-linux/usr/lib/pkgconfig pkg-config --modversion gbm | awk -F. '{printf "%2d%02d%02d", $1,$2,$3}')
if [ ${GBM_VERSION} -lt 170306 ]; then
    echo "update libgbm..."
    cd /tmp
    git clone git://github.com/renesas-rcar/libgbm
    cd libgbm
    git checkout match-mesa-17.3.6
    . /opt/poky/$1/environment-setup-aarch64-poky-linux
    libtoolize --automake
    autoreconf -vif -I ${OECORE_NATIVE_SYSROOT}/usr/share/aclocal
    ./configure ${CONFIGURE_FLAGS} --prefix=/usr
    make -j2
    make install DESTDIR=$SDKTARGETSYSROOT
    cd /tmp
    rm -rf libgbm
fi
