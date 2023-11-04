#!/bin/bash
set -e

if [ $# -ne 1 ]; then
  echo "$0 <install_dir>"
  exit 1
fi

SCRIPT_DIR=`cd $(dirname $0); pwd`
INSTALL_DIR=$1/_install

WEBRTC_VERSION=m119.6045.2.1
BOOST_VERSION=1.83.0
SORA_VERSION=2023.15.0
LYRA_VERSION=1.3.0

mkdir -p $INSTALL_DIR

if [ ! -e $INSTALL_DIR/webrtc ]; then
  file=webrtc.ubuntu-20.04_armv8.tar.gz
  curl -Lo $INSTALL_DIR/$file https://github.com/shiguredo-webrtc-build/webrtc-build/releases/download/${WEBRTC_VERSION}/${file}
  tar -xf $INSTALL_DIR/$file -C $INSTALL_DIR
fi

if [ ! -e $INSTALL_DIR/boost ]; then
  file=boost-${BOOST_VERSION}_sora-cpp-sdk-${SORA_VERSION}_ubuntu-20.04_armv8_jetson.tar.gz
  curl -Lo $INSTALL_DIR/$file https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/${file}
  tar -xf $INSTALL_DIR/$file -C $INSTALL_DIR
fi

if [ ! -e $INSTALL_DIR/sora ]; then
  file=sora-cpp-sdk-${SORA_VERSION}_ubuntu-20.04_armv8_jetson.tar.gz
  curl -Lo $INSTALL_DIR/$file https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/${file}
  tar -xf $INSTALL_DIR/$file -C $INSTALL_DIR
fi

if [ ! -e $INSTALL_DIR/lyra ]; then
  file=lyra-${LYRA_VERSION}_sora-cpp-sdk-${SORA_VERSION}_ubuntu-20.04_armv8_jetson.tar.gz
  curl -Lo $INSTALL_DIR/$file https://github.com/shiguredo/sora-cpp-sdk/releases/download/${SORA_VERSION}/${file}
  tar -xf $INSTALL_DIR/$file -C $INSTALL_DIR
fi