FROM ubuntu:18.04

ARG poky="2.4.3"

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y \
    lsb-release \
    sudo \
    tzdata

RUN apt-get install -y \
    curl \
    libgtkglext1-dev \
    wget \
    python3 \
    python3-pip \
    ninja-build

# Yocto requires the en_US.UTF-8 locale to work
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y locales

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8

RUN curl 'https://chromium.googlesource.com/chromium/src/+/master/build/install-build-deps.sh?format=TEXT' | base64 -d > install-build-deps.sh && \
    chmod 755 install-build-deps.sh && \
    ./install-build-deps.sh --no-chromeos-fonts

RUN pip3 install meson

COPY poky-glibc-x86_64-core-image-weston-sdk-aarch64-toolchain-${poky}.sh /tmp

RUN /tmp/poky-glibc-x86_64-core-image-weston-sdk-aarch64-toolchain-${poky}.sh && \
    cd /opt/poky/${poky}/sysroots/aarch64-poky-linux/usr/lib/aarch64-poky-linux/ && \
    cd $(ls) && cp *.o *.a ../../ && cd /tmp && \
    rm poky-glibc-x86_64-core-image-weston-sdk-aarch64-toolchain-${poky}.sh

COPY pipewire/meson.cross /tmp
COPY update_sysroot.sh /tmp
RUN bash /tmp/update_sysroot.sh ${poky} && rm /tmp/update_sysroot.sh

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8 

WORKDIR /home/build
CMD /bin/bash
