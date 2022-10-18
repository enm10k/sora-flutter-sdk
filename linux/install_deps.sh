#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "$0 <install_dir>"
  exit 1
fi

SCRIPT_DIR=`cd $(dirname $0); pwd`
INSTALL_DIR=$1/_install

WEBRTC_VERSION=m105.5195.0.0
BOOST_VERSION=1.80.0
SORA_VERSION=2022.14.0

mkdir -p $INSTALL_DIR

if [ ! -e $INSTALL_DIR/webrtc ]; then
  file=webrtc.ubuntu-20.04_x86_64-${WEBRTC_VERSION}.tar.gz
  curl -Lo $INSTALL_DIR/$file https://github.com/shiguredo-webrtc-build/webrtc-build/releases/download/${WEBRTC_VERSION}/webrtc.ubuntu-20.04_x86_64.tar.gz
  tar -xf $INSTALL_DIR/$file -C $INSTALL_DIR
fi

if [ ! -e $INSTALL_DIR/boost ]; then
  file=boost-${BOOST_VERSION}_sora-cpp-sdk-${SORA_VERSION}_ubuntu-20.04_x86_64.tar.gz
  curl -Lo $INSTALL_DIR/$file https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/${file}
  tar -xf $INSTALL_DIR/$file -C $INSTALL_DIR
fi

if [ ! -e $INSTALL_DIR/sora ]; then
  file=sora-cpp-sdk-${SORA_VERSION}_ubuntu-20.04_x86_64.tar.gz
  curl -Lo $INSTALL_DIR/$file https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/${file}
  tar -xf $INSTALL_DIR/$file -C $INSTALL_DIR
fi

source $INSTALL_DIR/webrtc/VERSIONS

if [ ! -e $INSTALL_DIR/llvm ]; then
  $SCRIPT_DIR/get_llvm.sh \
    $INSTALL_DIR/llvm \
    $WEBRTC_SRC_TOOLS_URL \
    $WEBRTC_SRC_TOOLS_COMMIT \
    $WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXX_TRUNK_URL \
    $WEBRTC_SRC_BUILDTOOLS_THIRD_PARTY_LIBCXX_TRUNK_COMMIT \
    $WEBRTC_SRC_BUILDTOOLS_URL \
    $WEBRTC_SRC_BUILDTOOLS_COMMIT
fi
