#!/bin/bash



OS=ios
ARCH=ios

cd $(dirname $0)
source config.sh
./setup.sh $OS $ARCH $SDK_VERSION $BOOST_VERSION $WEBRTC_VERSION $LYRA_VERSION
