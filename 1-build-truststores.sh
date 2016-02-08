#!/bin/bash


#set -x	  #uncomment for debuging

##################################################
#  1-BUILD-TRUSTSTORES
#  Generates self-signed CA 
#     (will reuse existing if present in authority folder)
#  adds all trust stores in trusts folder 
#  If want public trusts be sure to add a link to trusts
#  prior to running.
#  example:  ln -s $JAVA_HOME/jre/lib/security/cacerts trusts/public-trusts 
##################################################

SubjectPrefix="/C=US/ST=VA/L=Richmond/O=Example/CN"


[ ! -d staging  ] && mkdir staging 

if [ ! -d authority ]; then
	mkdir authority
	echo `date +%s` > authority/authority.srl
	
	#create empty truststore
	keytool -genkey -alias foo -keystore staging/trust.jks -dname "CN=foo" -storepass "changeit" -keypass "changeit"
	keytool -delete -alias foo -keystore staging/trust.jks -storepass "changeit"

	# Generate CA trust cert
	openssl req -x509 -extensions v3_ca -sha256 -nodes -days 1826 -newkey rsa:2048 -subj "$SubjectPrefix=Trust CA"  -keyout authority/authority.key -out authority/authority.crt
	openssl x509 -in authority/authority.crt -noout -text

fi
# Import This-ROOT-CA Authority into trust store
$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias "trust-ca" -file authority/authority.crt -keystore staging/trust.jks -storepass "changeit"


##### For every truststore in trusts folder add to staging
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")

for D in `find trusts/. -mindepth 1`
do
   echo ${D##*/}
  keytool -importkeystore -deststorepass changeit -destkeystore staging/trust.jks -srckeystore trusts/${D##*/} -srcstorepass changeit 


done
IFS=$SAVEIFS

