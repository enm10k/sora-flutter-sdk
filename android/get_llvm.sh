#!/bin/bash
set -e

if [ $# -ne 7 ]; then
  echo "$0 <install_dir> <tools_url> <tools_commit> <libcxx_url> <libcxx_commit> <buildtools_url> <buildtools_commit>"
  exit 1
fi

INSTALL_DIR=$1
TOOLS_URL=$2
TOOLS_COMMIT=$3
LIBCXX_URL=$4
LIBCXX_COMMIT=$5
BUILDTOOLS_URL=$6
BUILDTOOLS_COMMIT=$7

function git_clone_shallow() {
  url=$1
  commit=$2
  dir=$3

  rm -rf $dir
  mkdir -p $dir
  pushd $dir
    git init
    git remote add origin $url
    git fetch --depth=1 origin $commit
    git reset --hard FETCH_HEAD
  popd
}

mkdir -p $INSTALL_DIR
pushd $INSTALL_DIR
  # tools の update.py を叩いて特定バージョンの clang バイナリを拾う
  git_clone_shallow $TOOLS_URL $TOOLS_COMMIT tools
  python3 tools/clang/scripts/update.py --output-dir clang

  # 特定バージョンの libcxx を利用する
  git_clone_shallow $LIBCXX_URL $LIBCXX_COMMIT libcxx

  # __config_site のために特定バージョンの buildtools を取得する
  git_clone_shallow $BUILDTOOLS_URL $BUILDTOOLS_COMMIT buildtools
  cp buildtools/third_party/libc++/__config_site libcxx/include/__config_site
popd