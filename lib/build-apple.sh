#!/bin/bash
DIR="$( cd "$( dirname "$0"  )" && pwd  )"
BUILDTYPE=$1
BUILDHOST=""
HOME=$DIR
CMAKEBUILD_DIR=cmakebuild
OPENSSL=$HOME/openssl-OpenSSL_1_1_1w
N2NDIR=$HOME/n2n-3.1.1
N2NONTUN=$HOME/n2nOnTun

BASEOUTPATH=$HOME/build/
OUTPATH=""
OPENSSLTARGET=""
CPUARCH=""
SIMULATOR=iPhoneSimulator
IPHONE=iPhoneOS
MACOSX=MacOSX
ARM_MACOS=Macos_aarch64
X86_MACOS=Macos_x86_64
XCODEPATH=/Applications/Xcode.app/Contents/Developer/Platforms
SDKPATH=.platform/Developer/SDKs/
MINSDKVERSION=""
MACOS_IOS_RCN2N_DEFINE=""
WEBSOCKET_LISTEN_ALLIP=""


if [[ $(uname) != "Darwin" ]] ;then
    echo 这个脚本是针对Macos编写的
    exit 0;
fi

function exitprint() {
    echo "build type"
    echo ""
    echo "clean   :clean"
    echo "build   :clean and fast build rcvv(ios\macos)"
    echo "all     :clean and full build all (ios\macos)"
    echo "ipm-arm :clean and build ios simulator(arm)"
    exit 0
}

function unzip() {
    if [[  ! -e $OUTPATH ]];then
      mkdir -p $OUTPATH
      mkdir -p $OUTPATH/include
      mkdir -p $OUTPATH/lib
      mkdir -p $OUTPATH/bin
    fi
}

function buildn2n() {
    rm -rf ${N2NDIR}
    tar xvf ${N2NDIR}.tgz   || exit 1
    cd $N2NDIR              || exit 1
      rm -rf ${CMAKEBUILD_DIR};
      mkdir ${CMAKEBUILD_DIR}
      cd ${CMAKEBUILD_DIR}  || exit 1
      cmake .. -DCMAKE_INSTALL_PREFIX=$OUTPATH \
          -DCMAKE_SYSTEM_NAME=Darwin \
          -DCMAKE_C_FLAGS="$CPUARCH -fPIC -g -D__BUILD_WITH_EXLOG__" \
          -DCMAKE_CXX_FLAGS="$CPUARCH -fPIC -g -D__BUILD_WITH_EXLOG__" \
          -DCMAKE_OSX_SYSROOT=$SDKDIR || exit 1
      make n2n                        || exit 1
      cp libn2n.a $OUTPATH/lib
      if [[  ! -e $OUTPATH/include/n2n  ]];then
        mkdir -p $OUTPATH/include/n2n;
      fi
      cp -rfv ../include/*.h $OUTPATH/include/n2n
    cd ../..
}

function buildn2nOntun() {
    rm -rf $N2NONTUN
    tar xvf ${N2NONTUN}.tgz || exit 1;
    cd N2NONTUN            || exit 1;
      make clean
      make libn2nOntun.a CC="xcrun -sdk $XCRUN cc $CPUARCH -fPIC -g $MACOS_IOS_RCN2N_DEFINE -isysroot$SDKDIR -I$OUTPATH/include $MINSDKVERSION" \
              LDLIB=-L$OUTPATH/lib || exit 1
      make installlib INSTALLPATH=$OUTPATH  || exit 1
    cd ..
}

function buildedge() {
    rm -rf $N2NONTUN
    tar xvf ${N2NONTUN}.tgz || exit 1;
    cd $N2NONTUN            || exit 1;
      make clean
      make edge CC="xcrun -sdk $XCRUN cc $CPUARCH -fPIC -g -isysroot$SDKDIR -I$OUTPATH/include $MINSDKVERSION -D_BUILD_WITH_APPLE_MACOS_" \
             LD="xcrun -sdk $XCRUN cc $CPUARCH -fPIC -g" LDLIB=-L$OUTPATH/lib || exit 1
      make installedge INSTALLPATH=$OUTPATH  || exit 1
    cd ..
}


function buildAll() {
    unzip
    buildn2n
    buildn2nOntun
    if [[ $MACOS_IOS_RCN2N_DEFINE == "-D_BUILD_WITH_APPLE_MACOS_" ]];then
        buildedge
    fi
}

function buildMacosX86() {
    echo select build Macos_x86_64
    OPENSSLTARGET=darwin64-x86_64-cc
    OUTPATH=$BASEOUTPATH${X86_MACOS}
    SDKDIR=$XCODEPATH"/"$MACOSX$SDKPATH$MACOSX".sdk"
    XCRUN='macosx '
    CPUARCH="-target x86_64-apple-macos11.0"
    BUILDHOST=x86_64-apple-darwin
}

function buildMacosAarch64() {
    echo select build Macos_aarch
    OPENSSLTARGET=darwin64-arm64-cc
    OUTPATH=$BASEOUTPATH${ARM_MACOS}
    SDKDIR=$XCODEPATH"/"$MACOSX$SDKPATH$MACOSX".sdk"
    XCRUN='macosx '
    CPUARCH="-target arm64-apple-macos11.0"
    BUILDHOST=aarch64-apple-darwin
}

function buildiPhone() {
    echo select build $IPHONE
    OPENSSLTARGET=ios64-xcrun
    OUTPATH=$BASEOUTPATH$IPHONE
    SDKDIR=$XCODEPATH"/"$IPHONE$SDKPATH$IPHONE".sdk"
    XCRUN='iphoneos '
    CPUARCH="-target arm64-apple-ios14.5 -DHEART_FAIL_RELOGIN -D__IOS_CLOSERCVV_NO_LOGOUT__"
    BUILDHOST=aarch64-apple-darwin
}

function buildiPhoneSimulatorArm64() {
    echo select build $SIMULATOR
    OPENSSLTARGET=iossimulator-xcrun
    OUTPATH=$BASEOUTPATH$IPHONE
    SDKDIR=$XCODEPATH"/"$SIMULATOR$SDKPATH$SIMULATOR".sdk"
    XCRUN='iphonesimulator'
    CPUARCH="-target arm64-apple-ios14.5-simulator -DHEART_FAIL_RELOGIN -D__IOS_CLOSERCVV_NO_LOGOUT__"
    BUILDHOST=aarch64-apple-darwin
}

function buildiPhoneSimulatorX86() {
    echo select build $SIMULATOR
    OPENSSLTARGET=iossimulator-xcrun
    OUTPATH=$BASEOUTPATH$IPHONE
    SDKDIR=$XCODEPATH"/"$SIMULATOR$SDKPATH$SIMULATOR".sdk"
    XCRUN='iphonesimulator'
    CPUARCH="-target x86_64-apple-ios14.5-simulator -DHEART_FAIL_RELOGIN -D__IOS_CLOSERCVV_NO_LOGOUT__"
    BUILDHOST=x86_64-apple-darwin
}

function lipoMacos(){
    LIPOLIBS="libn2n.a,libn2nOntun.a"
    array=(${LIPOLIBS//,/ })
    for var in  ${array[@]}
    do
      lipoLib $var
    done

    lipoBin edge
}

function lipoLib() {
    echo "lipo $1"
    lipo -create $BASEOUTPATH$ARM_MACOS/lib/$1   $BASEOUTPATH$X86_MACOS/lib/$1 -output $BASEOUTPATH$MACOSX/lib/$1    || exit -1
}

function lipoBin() {
    echo "lipo $1"
    lipo -create $BASEOUTPATH$ARM_MACOS/bin/$1   $BASEOUTPATH$X86_MACOS/bin/$1 -output $BASEOUTPATH$MACOSX/bin/$1    || exit -1
}

function buildiosSimulator() {
    export IPHONEOS_DEPLOYMENT_TARGET=15.0
    buildiPhoneSimulatorArm64
    buildAll
    unset IPHONEOS_DEPLOYMENT_TARGET
}

function buildios() {
    export IPHONEOS_DEPLOYMENT_TARGET=15.0
    buildiPhone
    buildAll
    unset IPHONEOS_DEPLOYMENT_TARGET
}

function buildmacos() {
    export MACOSX_DEPLOYMENT_TARGET=11.0
    MACOS_IOS_RCN2N_DEFINE=-D_BUILD_WITH_APPLE_MACOS_
    buildMacosAarch64
    buildAll
    buildMacosX86
    buildAll
    OUTPATH=$BASEOUTPATH$MACOSX
    unzip
    lipoMacos
    cp -rfv $BASEOUTPATH$ARM_MACOS/include $BASEOUTPATH$MACOSX
    unset MACOSX_DEPLOYMENT_TARGET
    unset MACOS_IOS_RCN2N_DEFINE
}

if [[ $BUILDTYPE == "clean" ]];then
    rm -rf $N2NDIR
    rm -rf $N2NONTUN
    rm -rf $OPENSSL
    rm -rf $BASEOUTPATH$MACOSX
    rm -rf $BASEOUTPATH$IPHONE
    rm -rf $BASEOUTPATH$ARM_MACOS
    rm -rf $BASEOUTPATH$X86_MACOS
    exit 0;
elif [[ $BUILDTYPE == "all" ]];then
    START=$(date +%s)
    buildmacos
    buildios
    END=$(date +%s)
    echo build success;
    echo build as $((END-START)) seconds;
    exit 0;
elif  [[ $BUILDTYPE == "ipm-arm" ]];then
    START=$(date +%s)
    buildiosSimulator
    END=$(date +%s)
    echo build success;
    echo build as $((END-START)) seconds;
    exit 0;
else
    exitprint
fi
exit 0


