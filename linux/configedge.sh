#!/bin/bash


INPUT=""
SUPERNODE=""
LOCALIP=""
DST_EDGESERVER_FILE="/lib/systemd/system/edge.service"
SOR_EDGESERVER_FILE="/usr/local/n2n/edge.service"

echo "config edge service ? [yes/No]\n"
read INPUT
echo $INPUT
if [[ $INPUT == "y"  || $INPUT == "Y" || $INPUT == "yes" || $INPUT == "Yes" ]]; then

  echo "input supernode and port like 1.2.3.4:9994  or  example.com:9994 : [example.com:9994]\n "
  read SUPERNODE
  if [[ -z "$SUPERNODE" ]]; then
      SUPERNODE="example.com:9994"
  fi


  echo "input edge local ip like  192.168.1.2/16  [Default:dhcp]"
  read LOCALIP


  echo "edge info :\n"
  echo "supernode : "${SUPERNODE} "\n"
  echo "localip   : "${LOCALIP}  "\n"
  echo "warning: example.com:9994  only display,can't use"
  echo "warning: local ip is null ,then use dhcp"
  echo "are you sure :[Yes/no]\n"

  read INPUT
  if [[ $INPUT == "n" && $INPUT != "No" ]]; then
      echo "no change"
      exit 0
  fi

  cp -rfv  $SOR_EDGESERVER_FILE ${DST_EDGESERVER_FILE}
  sed -i 's#SUPERNODE_PORT#${SUPERNODE}#g' ${DST_EDGESERVER_FILE}
  sed -i 's#LOCSL_IP_MASK#${LOCSL_IP_MASK}#g' ${DST_EDGESERVER_FILE}

  systemctl daemon-reload
  echo "success"

fi