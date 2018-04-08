#!/bin/bash


#set -x	  #uncomment for debuging

##################################################
#  1-BUILD-TRUSTSTORES
#  Generates self-signed CA 
#     (will reuse existing if present in authority folder)
#  adds all trust stores in trusts folder 
#  If want public trusts be sure to add a link to trusts
#  prior to running.
#  example:  ln -s $JAVA_HOME/jre/lib/security/cacerts staging/trusts/public-trusts 
##################################################

. conf/vars.conf
today=`date '+%Y_%m_%d__%H_%M_%S'`;

export JAVA_HOME=$certtools_java_home

[ ! -d $certtools_home/staging  ] && mkdir -p $certtools_home/staging/trusts
[ ! -d $certtools_home/target  ] && mkdir -p $certtools_home/target

if [ ! -d $certtools_home/staging/authority ]; then
	mkdir $certtools_home/staging/authority
	mkdir $certtools_home/staging/root
	echo `date +%s` > $certtools_home/staging/authority/authority.srl
	
	# Generate CA trust cert
	openssl req -x509 -extensions v3_ca -sha256 -nodes -days 1826 -newkey rsa:2048 -subj "$SubjectPrefix=$TrustCN"  -keyout $certtools_home/staging/authority/authority.key -out $certtools_home/staging/authority/authority.crt
	openssl x509 -in $certtools_home/staging/authority/authority.crt -noout -text

fi
# Import This-ROOT-CA Authority into trust store
[ -f $certtools_home/staging/trust.jks  ] && rm $certtools_home/staging/trust.* 
$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias "trust-ca" -file $certtools_home/staging/authority/authority.crt -keystore $certtools_home/staging/trust.jks -storepass $masterPassword


##### For every truststore in trusts folder add to staging
####  Assumes master password is same for these imported trust stores
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for D in `find $certtools_home/staging/trusts/. -mindepth 1`
do
   echo ${D##*/}
  keytool -importkeystore -deststorepass $masterPassword -destkeystore $certtools_home/staging/trust.jks -srckeystore $certtools_home/staging/trusts/${D##*/} -srcstorepass $masterPassword 


done

IFS=$SAVEIFS

  keytool -importkeystore -deststorepass $masterPassword -destkeystore $certtools_home/staging/trust.jceks -deststoretype jceks -srckeystore $certtools_home/staging/trust.jks -srcstorepass $masterPassword 
  
  keytool -importkeystore -deststorepass $masterPassword -destkeystore $certtools_home/staging/trust.p12 -deststoretype PKCS12 -srckeystore $certtools_home/staging/trust.jks -srcstorepass $masterPassword 

cp -rf $certtools_home/staging/* $certtools_home/target/

