#!/bin/bash


#set -x   #uncomment for debuging

##################################################
#  4-GENERATE-USERS
#  Assumes CA signing certificates alread exist in
#  authority folder.
#  
#  Generates PCKS12 [.p12] keypair for client
#  or end user authentication
##################################################

SubjectPrefix="/C=US/ST=VA/L=Richmond/O=Example/CN"

rm -rf /tmp/certs
mkdir /tmp/certs

while read line
do

   	echo ${line}
	mkdir /tmp/certs/${line}
	mkdir staging/${line}

	# Generate client and server certs
	openssl genrsa -out /tmp/certs/${line}/${line}.key 2048
 
	# Gen server signing request. CN must equal the FQDN
	openssl req -sha256 -new -key /tmp/certs/${line}/${line}.key -out /tmp/certs/${line}/${line}.req -subj "$SubjectPrefix=${line}"
 
	# Now sign the certs 
	openssl x509 -sha256 -req -in /tmp/certs/${line}/${line}.req -CA authority/authority.crt -CAkey authority/authority.key  -extfile v3.ext -days 1826 -outform PEM -out /tmp/certs/${line}/${line}.crt
 
	# Create PKCS12 keystores
	openssl pkcs12 -export -in /tmp/certs/${line}/${line}.crt -inkey /tmp/certs/${line}/${line}.key -out staging/${line}/${line}.p12 -name ${line} -password pass:changeit

	# Import P12 keystore into JKS
	keytool -importkeystore -deststorepass changeit -destkeypass changeit  -destkeystore staging/${line}/${line}.jks -srckeystore staging/${line}/${line}.p12 -srcstoretype PKCS12 -srcstorepass changeit -alias ${line} 
	
 
	# Import the trust CA chain
	$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line} -file /tmp/certs/${line}/${line}.crt -keystore staging/trust.jks -storepass "changeit"

done <users.conf

