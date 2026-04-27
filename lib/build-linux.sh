#!/bin/bash
DIR="$( cd "$( dirname "$0"  )" && pwd  )"
BUILDTYPE=$1
BUILDHOST=""
HOME=$DIR
CMAKEBUILD_DIR=cmakebuild
OPENSSL=$HOME/openssl-OpenSSL_1_1_1w
N2NDIR=$HOME/n2n-3.1.1
BASEOUTPATH=$HOME/build/
OUTPATH=""
OPENSSLTARGET=""
CPUARCH=""
MINSDKVERSION=""
CPUARCH=linux-$(uname -m)

function exitprint() {
    echo "build type"
    echo ""
    echo "clean :rm -rf all exe and make clean"
    echo "all   :build all"
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
    rm -rf $N2NDIR
    tar xvf ${N2NDIR}.tgz || exit 1;
    cd $N2NDIR            || exit 1;
    rm -rf ${CMAKEBUILD_DIR};
    mkdir ${CMAKEBUILD_DIR}
    cd ${CMAKEBUILD_DIR}     || exit 1
        cmake .. -DCMAKE_INSTALL_PREFIX=$OUTPATH \
            -DCMAKE_SYSTEM_NAME=Linux \
            -DCMAKE_C_FLAGS=" -fPIC -g" \
            -DCMAKE_CXX_FLAGS=" -fPIC -g" \
            -DCMAKE_OSX_SYSROOT=$SDKDIR || exit 1
        make edge                       || exit 1
        make supernode                  || exit 1
        cp edge $OUTPATH/bin
        cp supernode $OUTPATH/bin
        cp libn2n.a  $OUTPATH/lib
        if [[  ! -e $OUTPATH/include/n2n  ]];then
          mkdir -p $OUTPATH/include/n2n;
        fi
        cp -rfv ../include/*.h $OUTPATH/include/n2n
    cd ../..
}

function clean() {
    rm -rf ${BASEOUTPATH}${CPUARCH};
    rm -rf $OPENSSL
    rm -rf $N2NDIR
}

function build() {
    unzip
    buildn2n
}

if [[ $BUILDTYPE == "clean" ]];then
    clean
    exit 0;
elif [[ $BUILDTYPE == "all" ]];then
    START=$(date +%s)
    OUTPATH=${BASEOUTPATH}${CPUARCH}
    OPENSSLTARGET=${CPUARCH}
    build
    END=$(date +%s)
    echo build success;
    echo echo run as $((END-START)) seconds;
    exit 0;
else
    exitprint
fi
exit


