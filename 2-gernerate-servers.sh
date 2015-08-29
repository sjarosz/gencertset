#!/bin/bash


#set -x	  #uncomment for debuging

##################################################
#  2-GENERATE-SERVERS
#  Assumes 1-BUILD-TRUSTSTORES has been run
#  For every entry in fqdn.conf, generates keypair for SSL 
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
	mkdir staging/${line}

		# Generate client and server certs

		################  Client  ###########
		openssl genrsa -out /tmp/certs/${line}/${line}-Client.key 2048
		
		# Gen client signing request.  Client Certificate CN should match FQDN
		openssl req -sha256 -new -key /tmp/certs/${line}/${line}-Client.key -out /tmp/certs/${line}/${line}-Client.req -subj "$SubjectPrefix=${line}"
 
		# Now sign the certs 
		openssl x509 -sha256 -req -in /tmp/certs/${line}/${line}-Client.req -CA authority/authority.crt -CAkey authority/authority.key  -extfile v3.ext -days 1826 -outform PEM -out /tmp/certs/${line}/${line}-Client.crt
 
		# Create PKCS12 keystores
		openssl pkcs12 -export -in /tmp/certs/${line}/${line}-Client.crt -inkey /tmp/certs/${line}/${line}-Client.key -out staging/${line}/${line}-Client.p12 -name ${line} -password pass:changeit

		# Import P12 keystore into JKS
		keytool -importkeystore -deststorepass changeit -destkeypass changeit  -destkeystore staging/${line}/${line}.jks -srckeystore staging/${line}/${line}-Client.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias ${line} 
	
 
		# Import the trust CA chain
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line}-Client -file /tmp/certs/${line}/${line}-Client.crt -keystore staging/trust.jks -storepass "changeit"

		################  Client  ###########
		################  Server SSL  ###########
		openssl genrsa -out /tmp/certs/${line}/${line}-SSL.key 2048
	
		# Gen server signing request. Server Cert, CN is set to *.domainname for SSL listener *. + ${line#*.} achieves parse
		openssl req -sha256 -new -key /tmp/certs/${line}/${line}-SSL.key -out /tmp/certs/${line}/${line}-SSL.req -subj "$SubjectPrefix=*.${line#*.}"
		
		# Now sign the certs 
		openssl x509 -sha256 -req -in /tmp/certs/${line}/${line}-SSL.req -CA authority/authority.crt -CAkey authority/authority.key  -extfile v3.ext -days 1826 -outform PEM -out /tmp/certs/${line}/${line}-SSL.crt
 
		# Create PKCS12 keystores
		openssl pkcs12 -export -in /tmp/certs/${line}/${line}-SSL.crt -inkey /tmp/certs/${line}/${line}-SSL.key -out staging/${line}/${line}-SSL.p12 -name ${line#*.} -password pass:changeit

		# Import P12 keystore into JKS
		keytool -importkeystore -deststorepass changeit -destkeypass changeit  -destkeystore staging/${line}/${line}.jks -srckeystore staging/${line}/${line}-SSL.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias ${line#*.} 
	
 
		# Import the trust CA chain
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line#*.}-SSL -file /tmp/certs/${line}/${line}-SSL.crt -keystore staging/trust.jks -storepass "changeit"

		################  Server SSL  ###########
done <fqdn.conf

