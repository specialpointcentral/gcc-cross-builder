FROM ubuntu:20.04
MAINTAINER Matt Godbolt <matt@godbolt.org>

ARG DEBIAN_FRONTEND=noninteractive

# Annoyingly crosstool whinges if it's run as root.
RUN mkdir -p /opt && mkdir -p /home/gcc-user && useradd gcc-user && chown gcc-user /opt /home/gcc-user

RUN apt-get clean -y && apt-get check -y

RUN apt-get update -y -q && apt-get upgrade -y -q && apt-get upgrade -y -q && \
    apt-get install -y -q \
    autoconf \
    automake \
    libtool \
    bison \
    bzip2 \
    curl \
    file \
    flex \
    git \
    gawk \
    binutils-multiarch \
    gperf \
    help2man \
    libc6-dev-i386 \
    libncurses5-dev \
    libtool-bin \
    linux-libc-dev \
    make \
    ninja-build \
    device-tree-compiler \
    patch \
    rsync \
    s3cmd \
    sed \
    subversion \
    texinfo \
    wget \
    unzip \
    autopoint \
    gettext \
    vim \
    zlib1g-dev \
    software-properties-common \
    xz-utils && \
    cd /tmp && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf aws* && \
    mkdir -p /opt/compiler-explorer/ && \
    cd /opt/compiler-explorer && \
    curl "https://compiler-explorer.s3.amazonaws.com/opt/gcc-12.1.0.tar.xz" -o gcc12.tar.xz && \
    tar Jxvf gcc12.tar.xz && \
    rm gcc12.tar.xz

## Need for host GCC version to be >= latest cross GCC being built.
## This is at least needed for building cross-GNAT (Ada) as the GNAT runtime has no
## requirement on a minimal supported version (e.g. need GCC 12 to build any GNAT runtime).
## This is only true for cross compiler. Native compiler can use host's runtime
## and bootstrap everything.
ENV PATH="/opt/compiler-explorer/gcc-12.1.0/bin:${PATH}"
ENV LD_LIBRARY_PATH="/opt/compiler-explorer/gcc-12.1.0/lib:${PATH}"

WORKDIR /opt

## This patch is needed to force ct-ng to not error out because we are setting
## LD_LIBRARY_PATH. There's no easy way to have ct-ng use a particular compiler
## (...). If we have strange behavior, maybe we'll have to look at this.
## Couldn't see anything suspicious (yet).
COPY build/patches/crosstool-ng/ld_library_path.patch ./

## TAG is pointing to a specific ct-ng revision (usually the current dev one
## when updating this script or ct-ng)
RUN TAG=cf9beb1e4fadda47a3251eaea2d701555dcdf957 && \
    curl -sL https://github.com/crosstool-ng/crosstool-ng/archive/${TAG}.zip --output crosstool-ng-master.zip  && \
    unzip crosstool-ng-master.zip && \
    cd crosstool-ng-${TAG} && \
    patch -p1 < ../ld_library_path.patch && \
    ./bootstrap && \
    ./configure --prefix=/opt/crosstool-ng-latest && \
    make -j$(nproc) && \
    make install

RUN mkdir -p /opt/.build/tarballs
COPY build /opt/
RUN chown -R gcc-user /opt
USER gcc-user
