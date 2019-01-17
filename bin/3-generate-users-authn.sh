#!/bin/bash

#set -x   #uncomment for debuging

##################################################
#  3-GENERATE-USERS
#  Assumes CA signing certificates alread exist in
#  authority folder.
#
#  Generates PCKS12 [.p12] keypair for client
#  or end user authentication
#  Certificate contains SubjectAltName compatible with Windows and PIV
##################################################


. conf/vars.conf
export JAVA_HOME=$certtools_java_home


[ ! -d $certtools_home/staging/authority  ] && exit 1
[ ! -d $certtools_home/target/public/users_clients  ] && mkdir -p $certtools_home/target/public/users_clients
[ ! -d $certtools_home/target/users_clients/p12  ] && mkdir -p $certtools_home/target/users_clients/p12
[ ! -d $certtools_home/target/users_clients/public  ] && mkdir -p $certtools_home/target/users_clients/public


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
        # if email form, then assign name to subject and email form to UPN
        if [[ $line =~ ^[A-Za-z0-9._%+-]+[^@] ]]
           then
              echo "email form"
	      openssl req -newkey rsa:2048 -nodes -keyout $certtools_home/staging/${line}/${line}.key -subj "$SubjectPrefix=${BASH_REMATCH[0]}" -out $certtools_home/staging/${line}/${line}.req
        fi


	# Now sign the certs
	openssl x509 -sha256 -req -in $certtools_home/staging/${line}/${line}.req -CA $certtools_home/staging/authority/authority.crt -CAkey $certtools_home/staging/authority/authority.key  -extfile  <(printf "subjectAltName=otherName:1.3.6.1.4.1.311.20.2.3;UTF8:${line}")  -days 1826 -outform PEM -out $certtools_home/staging/${line}/${line}.crt

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

cp -rf $certtools_home/staging/${line}/${line}.crt $certtools_home/target/public/users_clients
cp -rf $certtools_home/staging/${line}/${line}.crt $certtools_home/target/users_clients/public
cp -rf $certtools_home/staging/${line}/${line}.p12 $certtools_home/target/users_clients/p12

done <$certtools_home/conf/users.conf
                # Update trust.p12
  rm $certtools_home/staging/trust.p12
  $JAVA_HOME/bin/keytool -importkeystore -deststorepass $masterPassword -destkeystore $certtools_home/staging/trust.p12 -deststoretype PKCS12 -srckeystore $certtools_home/staging/trust.jks -srcstorepass $masterPassword
cp -rf $certtools_home/staging/trust.* $certtools_home/target/truststores
