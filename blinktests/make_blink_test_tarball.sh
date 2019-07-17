#!/bin/bash

if [ -z $1 ]; then
   echo "Usage $0 <Path to compiled chromium source>"
   exit 1
fi
(cd $1; \
tar cf blink_tests.tar --transform='s/_GN_arm64//' --checkpoint=.1000 \
    net \
    third_party/blink \
    third_party/pywebsocket \
    out/Release_GN_arm64/content_shell* \
    out/Release_GN_arm64/*.dat \
    out/Release_GN_arm64/image_diff \
    out/Release_GN_arm64/*.so \
    out/Release_GN_arm64/locales \
    out/Release_GN_arm64/pyproto \
    out/Release_GN_arm64/resources \
    out/Release_GN_arm64/*.pak \
    out/Release_GN_arm64/*.bin \
    out/Release_GN_arm64/swiftshader \
    out/Release_GN_arm64/test_fonts \
    out/Release_GN_arm64/ui \
    out/Release_GN_arm64/wtf_unittests)
mv $1/blink_tests.tar .
tar --append -f blink_tests.tar yocto-httpd-2.4.conf
gzip blink_tests.tar
