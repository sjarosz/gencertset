#!/bin/bash


#set -x	  #uncomment for debuging

##################################################
#  5-PUBLISH
#  Copy the keystores and certificates into FRDP
#  deployment location.
##################################################


. conf/vars.conf

export JAVA_HOME=$certtools_java_home

[ ! -d $certtools_home/staging/authority  ] && exit 1
[ ! -d $certtools_home/target/public/servers  ] && mkdir -p $certtools_home/target/public/servers

while read line
do
       echo Checking status of ${line}
       if [ ! -d $certtools_home/target/servers/${line}  ]; then  continue
       fi

   	echo Processing ${line}
        cp -rf $certtools_home/target/servers/${line}/*.jks $keystores_destination
        cp -rf $certtools_home/target/servers/${line}/*.jceks $keystores_destination
        cp -rf $certtools_home/target/servers/${line}/*.p12 $keystores_destination
        cp -rf $certtools_home/target/servers/${line}/*.crt $certs_destination
        cp -rf $certtools_home/target/servers/${line}/*.key $keys_destination

done <$certtools_home/conf/fqdn.conf
