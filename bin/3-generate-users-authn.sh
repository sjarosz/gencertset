#!/bin/bash


#set -x   #uncomment for debuging

##################################################
#  3-GENERATE-USERS
#  Assumes CA signing certificates alread exist in
#  authority folder.
#  
#  Generates PCKS12 [.p12] keypair for client
#  or end user authentication
##################################################


. conf/vars.conf
export JAVA_HOME=$certtools_java_home


[ ! -d $certtools_home/staging/authority  ] && exit 1

while read line
do

        echo Checking status of ${line}
        if [  -d $certtools_home/staging/${line}  ]; then  continue
        fi

   	echo ${line}
	mkdir $certtools_home/staging/${line}

	# Generate client and server certs
	openssl genrsa -out $certtools_home/staging/${line}/${line}.key 2048
 
	# Gen server signing request. CN must equal the FQDN
	openssl req -sha256 -new -key $certtools_home/staging/${line}/${line}.key -out $certtools_home/staging/${line}/${line}.req -subj "$SubjectPrefix=${line}"
 
	# Now sign the certs 
	openssl x509 -sha256 -req -in $certtools_home/staging/${line}/${line}.req -CA $certtools_home/staging/authority/authority.crt -CAkey $certtools_home/staging/authority/authority.key  -extfile $certtools_home/conf/v3.ext -days 1826 -outform PEM -out $certtools_home/staging/${line}/${line}.crt
 
	# Create PKCS12 keystores
	openssl pkcs12 -export -in $certtools_home/staging/${line}/${line}.crt -inkey $certtools_home/staging/${line}/${line}.key -out staging/${line}/${line}.p12 -name ${line} -password pass:$masterPassword

	# Import P12 keystore into JKS
	#keytool -importkeystore -deststorepass $masterPassword -destkeypass $masterPassword  -destkeystore $certtools_home/staging/${line}/${line}.jks -srckeystore $certtools_home/staging/${line}/${line}.p12 -srcstoretype PKCS12 -srcstorepass $masterPassword -alias ${line} 
	
	# Import P12 keystore into JCEKS
	#keytool -importkeystore -deststorepass $masterPassword -destkeypass $masterPassword  -destkeystore $certtools_home/staging/${line}/${line}.jceks -deststoretype JCEKS -srckeystore $certtools_home/staging/${line}/${line}.p12 -srcstoretype PKCS12 -srcstorepass $masterPassword -alias ${line} 
 
	# Import P12 keystore into trust CA chain JKS
	$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line} -file $certtools_home/staging/${line}/${line}.crt -storetype JKS -keystore $certtools_home/staging/trust.jks -storepass $masterPassword

	# Import P12 keystore into trust CA chain JCEKS
	$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line} -file $certtools_home/staging/${line}/${line}.crt -storetype JCEKS -keystore $certtools_home/staging/trust.jceks -storepass $masterPassword

done <$certtools_home/conf/users.conf
cp -rf $certtools_home/staging/trust.* $certtools_home/target

