#!/bin/bash
DIR="$( cd "$( dirname "$0"  )" && pwd  )"
BUILDTYPE=$1

if [[ $(uname) == "Darwin" ]];then
  ANDROID_NDK=${HOME}/Library/Android/sdk/ndk/28.2.13676358
else
  ANDROID_NDK=${HOME}/Android/Sdk/ndk/28.2.13676358
fi

MINSDK=29
ROOTDIR=""
HOME=$DIR
CMAKEBUILD_DIR=cmakebuild
N2NDIR=$HOME/n2n-3.1.1
N2NONTUN=$HOME/n2nOnTun
OPENSSL=$HOME/openssl-OpenSSL_1_1_1w
BASEOUTPATH=$HOME/build/android/
OUTPATH=""
OPENSSLTARGET=""
SEDCMD=""
RUNARCH=""
ADNDOID_NDK_CC=""

if [[  ! -e $ANDROID_NDK  ]];then
  echo 没有找到ndk ,需要android-ndk-r28 $ANDROID_NDK
  exit 0;
fi

export ANDROID_NDK=$ANDROID_NDK

if [[ $(uname) != "Darwin" && $(uname) != "Linux" ]] ;then
    echo 构建 android 你需要一个安装了android-ndk-r27的苹果电脑或者Linux
    exit 0;
fi

function exitprint() {
    echo "UTF-8"
    echo "现在支持的编译选项"
    echo "x86    用在安卓模拟器上"
    echo "x86_64 用在安卓模拟器上"
    echo "armv8  armv8指令集，现在大部分手机，    64bit"
    echo "armv7  armv7指令集，稍微早期一些的手机， 32bit"
    echo "all  全部编译所有"
    echo ""
    echo "需要 ndk版本为 android-ndk-r28e 最小sdk版本为"$MINSDK
    echo "你需要更改脚本中的 环境变量ANDROID_NDK"
    exit 0
}

function unzip() {
    if [[  ! -e $OUTPATH ]];then
      mkdir -p $OUTPATH
      mkdir -p $OUTPATH/include
      mkdir -p $OUTPATH/lib
    fi
}

function buildn2n() {
    rm -rf ${N2NDIR}
    tar xvf ${N2NDIR}.tgz   || exit 1
    cd $N2NDIR              || exit 1
      rm -rf $CMAKEBUILD_DIR;
      mkdir $CMAKEBUILD_DIR
      cd $CMAKEBUILD_DIR    || exit 1
      cmake .. -DCMAKE_INSTALL_PREFIX=$OUTPATH \
          -DCMAKE_ANDROID_ARCH_ABI=$OUTARCH \
          -DCMAKE_ANDROID_API=29 \
          -DCMAKE_SYSTEM_NAME=android \
          -DCMAKE_C_FLAGS="-fPIC -g -D__BUILD_WITH_EXLOG__" \
          -DCMAKE_CXX_FLAGS="-fPIC -g -D__BUILD_WITH_EXLOG__" \
          -DCMAKE_ANDROID_NDK=$ANDROID_NDK || exit 1
      make n2n                        || exit 1
      cp libn2n.a $OUTPATH/lib

      if [[  ! -e $OUTPATH/include/n2n  ]];then
        mkdir -p $OUTPATH/include/n2n;
      fi
      cp -rfv ../include/*.h $OUTPATH/include/n2n
    cd ../..
}

function buildn2nOnTun() {
    rm -rf $N2NONTUN
    tar xvf ${N2NONTUN}.tgz || exit 1;
    cd $N2NONTUN            || exit 1;
      make clean
      make libn2nOntun.a CC="$ADNDOID_NDK_CC -fPIC -g -isysroot$ROOTDIR -I$OUTPATH/include -I$OUTPATH/include/n2n" \
              LD="llvm-ar -r"  || exit 1
      make installlib INSTALLPATH=$OUTPATH  || exit 1
    cd ..
}

function buildall() {
    unzip
    buildn2n
    buildn2nOnTun
}

if [[ $(uname) == "Linux" ]];then
  echo run in linux
  SEDCMD='sed -i '
  RUNARCH=linux-x86_64
fi

if [[ $(uname) == "Darwin" ]];then
  echo run in macos
  SEDCMD="sed -i '.bak' "
  RUNARCH=darwin-x86_64
fi

function buildx86() {
    echo select build arch x86
    export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/bin:$PATH
    ROOTDIR=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/sysroot
    OPENSSLTARGET=android-x86
    OUTPATH=${BASEOUTPATH}x86
    ADNDOID_NDK_CC=i686-linux-android${MINSDK}-clang
    OUTARCH=x86
    BUILDARCH=i686-linux-android
}

function buildarmv8() {
    echo select build arch arm64-v8a
    export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/bin:$PATH
    ROOTDIR=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/sysroot
    OPENSSLTARGET=android-arm64
    OUTPATH=${BASEOUTPATH}arm64
    ADNDOID_NDK_CC=aarch64-linux-android${MINSDK}-clang
    OUTARCH=arm64-v8a
    BUILDARCH=aarch64-linux-android
}

function buildarmv7() {
    echo select build arch armv7
    export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/bin:$PATH
    ROOTDIR=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/sysroot
    OPENSSLTARGET=android-arm
    OUTPATH=${BASEOUTPATH}arm
    ADNDOID_NDK_CC=armv7a-linux-androideabi${MINSDK}-clang
    OUTARCH=armeabi-v7a
    BUILDARCH=armv7a-linux-androideabi
}


function buildx86_64() {
    echo select build arch x86_64
    export PATH=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/bin:$PATH
    ROOTDIR=$ANDROID_NDK/toolchains/llvm/prebuilt/$RUNARCH/sysroot
    OPENSSLTARGET=android-x86_64
    OUTPATH=${BASEOUTPATH}x86_64
    ADNDOID_NDK_CC=x86_64-linux-android${MINSDK}-clang
    OUTARCH=x86_64
    BUILDARCH=x86_64-linux-android
}

if [[ $BUILDTYPE == "all" ]];then
    START=$(date +%s)
    buildx86
    buildall
    buildx86_64
    buildall
    buildarmv8
    buildall
    buildarmv7
    buildall
    END=$(date +%s)
    echo build success;
    echo echo run as $((END-START)) seconds;
    exit 0;
elif [[ $BUILDTYPE == "x86" ]];then
    START=$(date +%s)
    buildx86
    buildall
    END=$(date +%s)
    echo build success;
    echo echo run as $((END-START)) seconds;
    exit 0;
elif [[ $BUILDTYPE == "x86_64" ]];then
    START=$(date +%s)
    buildx86_64
    buildall
    END=$(date +%s)
    echo build success;
    echo echo run as $((END-START)) seconds;
    exit 0;
elif [[ $BUILDTYPE == "armv8" ]];then
    START=$(date +%s)
    buildarmv8
    buildall
    END=$(date +%s)
    echo build success;
    echo echo run as $((END-START)) seconds;
    exit 0;
elif [[ $BUILDTYPE == "armv7" ]];then
    START=$(date +%s)
    buildarmv7
    buildall
    END=$(date +%s)
    echo build success;
    echo echo run as $((END-START)) seconds;
    exit 0;
elif [[ $BUILDTYPE == "clean" ]] ;then
    rm -rf $BASEOUTPATH
    rm -rf $N2NDIR
    rm -rf $N2NONTUN
    rm -rf $OPENSSL
    exit 0
else
    exitprint
fi

exit 0
