#!/bin/bash


#set -x	  #uncomment for debuging

##################################################
#  4-ADD-PUBLIC-TRUSTSTORES
#  adds all trust stores in trusts folder 
#  from $JAVA_HOME trusts
#  prior to running.
#  example:  ln -s $JAVA_HOME/jre/lib/security/cacerts staging/trusts/public-trusts 
##################################################

. conf/vars.conf

# export JAVA_HOME=/usr/java


  keytool -importkeystore -deststorepass $masterPassword -destkeystore $certtools_home/target/trust.jks -srckeystore $JAVA_HOME/jre/lib/security/cacerts  -srcstorepass changeit 


