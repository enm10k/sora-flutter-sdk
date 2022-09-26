#!/bin/bash

OS=macos
ARCH=macos_arm64

cd $(dirname $0)
source config.sh
./setup.sh $OS $ARCH $SDK_VERSION $BOOST_VERSION $WEBRTC_VERSION
