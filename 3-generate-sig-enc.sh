#!/bin/bash

# export JAVA_HOME=/usr/java

#set -x	  #uncomment for debuging
##################################################
#  3-GENERATE-DIG-SIG
#  Assumes CA signing certificates already exist in
#  authority folder.
#
#  Generates digital Signing and Encryption
#  key pairs for each fqdn
##################################################

SubjectPrefix="/C=US/ST=VA/L=Richmond/O=Example/CN"

rm -rf /tmp/certs
mkdir /tmp/certs

[ ! -d staging  ] && exit 1 
[ ! -d authority  ] && exit 1 

while read line
do
   	echo ${line}
	mkdir /tmp/certs/${line}
	[ ! -d staging/${line}  ] && mkdir staging/${line}

		# Generate client and server certs

		################  Signature ##########
		openssl genrsa -out /tmp/certs/${line}/${line}-digsig.key 2048
		
		# Gen client signing request.  Client Certificate CN should match FQDN
		openssl req -sha256 -new -key /tmp/certs/${line}/${line}-digsig.key -out /tmp/certs/${line}/${line}-digsig.req -subj "$SubjectPrefix=${line}-digsig"
 
		# Now sign the certs 
		openssl x509 -sha256 -req -in /tmp/certs/${line}/${line}-digsig.req -CA authority/authority.crt -CAkey authority/authority.key  -extfile v3.ext -days 1826 -outform PEM -out /tmp/certs/${line}/${line}-digsig.crt
 
		# Create PKCS12 keystores
		openssl pkcs12 -export -in /tmp/certs/${line}/${line}-digsig.crt -inkey /tmp/certs/${line}/${line}-digsig.key -out staging/${line}/${line}-digsig.p12 -name ${line}-digsig -password pass:changeit

		# Import P12 keystore into JKS
		keytool -importkeystore -deststorepass changeit -destkeypass changeit  -destkeystore staging/${line}/${line}.jks -srckeystore staging/${line}/${line}-digsig.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias ${line}-digsig 
	
 
		# Import the trust CA chain
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line}-digsig -file /tmp/certs/${line}/${line}-digsig.crt -keystore staging/trust.jks -storepass "changeit"

		################  Signature  ###########
		################  Encryption  ###########
		openssl genrsa -out /tmp/certs/${line}/${line}-digenc.key 2048
	
		# Gen server signing request. Server Cert, CN is set to *.domainname for SSL listener *. + ${line#*.} achieves parse
		openssl req -sha256 -new -key /tmp/certs/${line}/${line}-digenc.key -out /tmp/certs/${line}/${line}-digenc.req -subj "$SubjectPrefix=${line}-digenc"
		
		# Now sign the certs 
		openssl x509 -sha256 -req -in /tmp/certs/${line}/${line}-digenc.req -CA authority/authority.crt -CAkey authority/authority.key  -extfile v3.ext -days 1826 -outform PEM -out /tmp/certs/${line}/${line}-digenc.crt
 
		# Create PKCS12 keystores
		openssl pkcs12 -export -in /tmp/certs/${line}/${line}-digenc.crt -inkey /tmp/certs/${line}/${line}-digenc.key -out staging/${line}/${line}-digenc.p12 -name ${line}-digenc -password pass:changeit

		# Import P12 keystore into JKS
		keytool -importkeystore -deststorepass changeit -destkeypass changeit  -destkeystore staging/${line}/${line}.jks -srckeystore staging/${line}/${line}-digenc.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias ${line}-digenc
	
 
		# Import the trust CA chain
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line}-digenc -file /tmp/certs/${line}/${line}-digenc.crt -keystore staging/trust.jks -storepass "changeit"

		################  Encryption  ###########
done <fqdn.conf

