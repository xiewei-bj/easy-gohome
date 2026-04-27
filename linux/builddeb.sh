
OSVERSION=1.0
SUPERNODE=n2n


cd ../lib/            || exit 1
./build-linux.sh all  || exit 1
cd ../linux           || exit 1

rm -rf $SUPERNODE
mkdir -p $SUPERNODE/DEBIAN/
mkdir -p $SUPERNODE/usr/local/$SUPERNODE/
mkdir -p $SUPERNODE/lib/systemd/system/
cp ../lib/build/linux-$(uname -m)/bin/supernode  $SUPERNODE/usr/local/$SUPERNODE/
cp ../lib/build/linux-$(uname -m)/bin/edge       $SUPERNODE/usr/local/$SUPERNODE/
cp configedge.sh                                 $SUPERNODE/usr/local/$SUPERNODE/
cp deb/*    $SUPERNODE/DEBIAN
cp supernode.service  $SUPERNODE/lib/systemd/system/
cp edge.service       $SUPERNODE/lib/systemd/system/
cp edge.service       $SUPERNODE/usr/local/$SUPERNODE/
sed -i "s/VERS/${OSVERSION}/"                 $SUPERNODE/DEBIAN/control
sed -i "s/ARCH/$(dpkg --print-architecture)/" $SUPERNODE/DEBIAN/control
dpkg-deb --build $SUPERNODE || exit 0;
rm -rf $SUPERNODE
mv n2n.deb n2n-$(uname -m).deb
