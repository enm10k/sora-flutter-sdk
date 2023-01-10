#!/bin/bash

# USAGE: setup.sh (ios|macos) (arm64) SDK_VERSION BOOST_VERSION WEBRTC_VERSION LYRA_VERSION

# バイナリをダウンロードする

OS=$1
ARCH=$2
SDK_VERSION=$3
BOOST_VERSION=$4
WEBRTC_VERSION=$5
LYRA_VERSION=$6

SDK_FILE=sora-cpp-sdk-${SDK_VERSION}_${ARCH}.tar.gz
BOOST_FILE=boost-${BOOST_VERSION}_sora-cpp-sdk-${SDK_VERSION}_${ARCH}.tar.gz
WEBRTC_FILE=webrtc.$ARCH.tar.gz
LYRA_FILE=lyra-${LYRA_VERSION}_sora-cpp-sdk-${SDK_VERSION}_${ARCH}.tar.gz
SDK_URL=https://github.com/shiguredo/sora-cpp-sdk/releases/download/$SDK_VERSION/$SDK_FILE
BOOST_URL=https://github.com/shiguredo/sora-cpp-sdk/releases/download/$SDK_VERSION/$BOOST_FILE
WEBRTC_URL=https://github.com/shiguredo-webrtc-build/webrtc-build/releases/download/$WEBRTC_VERSION/$WEBRTC_FILE
LYRA_URL=https://github.com/shiguredo/sora-cpp-sdk/releases/download/$SDK_VERSION/$LYRA_FILE

SETUP_DIR=_install


cd ../../$(dirname $0)/$OS

mkdir -p $SETUP_DIR
cd $SETUP_DIR
pwd

if [ ! -e $SDK_FILE ]; then
  echo "Download $SDK_FILE..."
  curl -fLo $SDK_FILE $SDK_URL
  tar xzf $SDK_FILE
fi
if [ ! -e $BOOST_FILE ]; then
  echo "Download $BOOST_FILE..."
  curl -fLo $BOOST_FILE $BOOST_URL
  tar xzf $BOOST_FILE
fi
if [ ! -e $WEBRTC_FILE ]; then
  echo "Download $WEBRTC_FILE..."
  curl -fLo $WEBRTC_FILE $WEBRTC_URL
  tar xzf $WEBRTC_FILE
fi
if [ ! -e $LYRA_FILE ]; then
  echo "Download $LYRA_FILE..."
  curl -fLo $LYRA_FILE $LYRA_URL
  tar xzf $LYRA_FILE
fi
