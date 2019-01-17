#!/bin/bash


#set -x	  #uncomment for debuging

##################################################
#  2-GENERATE-SERVERS
#  Assumes 1-BUILD-TRUSTSTORES has been run
#  For every entry in fqdn.conf, generates keypair for SSL
##################################################


. conf/vars.conf

export JAVA_HOME=$certtools_java_home

[ ! -d $certtools_home/staging/authority  ] && exit 1
[ ! -d $certtools_home/target/public/servers  ] && mkdir -p $certtools_home/target/public/servers
[ ! -d $certtools_home/target/servers  ] && mkdir -p $certtools_home/target/servers

while read line
do
       echo Checking status of ${line}
       if [  -d $certtools_home/staging/${line}  ]; then  continue
       fi

   	echo Processing ${line}
	mkdir $certtools_home/staging/${line}
	mkdir $certtools_home/target/servers/${line}
	[ ! -d $certtools_home/staging/${line}  ] && mkdir $certtools_home/staging/${line}

		# Generate client and server certs

		################  Client  ###########
		openssl genrsa -out $certtools_home/staging/${line}/${line}-Client.key 2048

		# Gen client signing request.  Client Certificate CN should match FQDN
		openssl req -sha256 -new -key $certtools_home/staging/${line}/${line}-Client.key -out $certtools_home/staging/${line}/${line}-Client.req -subj "$SubjectPrefix=${line}"

		# Now sign the certs
		openssl x509 -sha256 -req -in $certtools_home/staging/${line}/${line}-Client.req -CA $certtools_home/staging/authority/authority.crt -CAkey $certtools_home/staging/authority/authority.key  -extfile $certtools_home/conf/v3.ext -days 1826 -outform PEM -out $certtools_home/staging/${line}/${line}-Client.crt

		# Create PKCS12 keystores
		openssl pkcs12 -export -in $certtools_home/staging/${line}/${line}-Client.crt -inkey $certtools_home/staging/${line}/${line}-Client.key -out $certtools_home/staging/${line}/${line}-Client.p12 -name ${line} -password pass:$masterPassword

		# Import P12 keystore into JKS
		$JAVA_HOME/bin/keytool -importkeystore -deststorepass $masterPassword -destkeypass $masterPassword  -destkeystore $certtools_home/staging/${line}/${line}.jks -srckeystore $certtools_home/staging/${line}/${line}-Client.p12 -srcstoretype PKCS12 -srcstorepass $masterPassword -alias ${line}

		# Import P12 keystore into JCEKS
  $JAVA_HOME/bin/keytool -importkeystore -deststorepass $masterPassword -destkeystore $certtools_home/staging/${line}/${line}.jceks -deststoretype jceks -srckeystore $certtools_home/staging/${line}/${line}-Client.p12 -srcstoretype PKCS12 -srcstorepass $masterPassword


		# Import the trust CA chain into JKS
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line}-Client -file $certtools_home/staging/${line}/${line}-Client.crt -keystore $certtools_home/staging/trust.jks -storepass $masterPassword

		# Import the trust CA chain into JCEKS
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line}-Client -file $certtools_home/staging/${line}/${line}-Client.crt -storetype jceks -keystore $certtools_home/staging/trust.jceks -storepass $masterPassword
		################  Client  ###########
		################  Server SSL  ###########
		openssl genrsa -out $certtools_home/staging/${line}/${line}-SSL.key 2048

		# Gen server signing request. Server Cert, CN is set to *.domainname for SSL listener *. + ${line#*.} achieves parse
		openssl req -sha256 -new -key $certtools_home/staging/${line}/${line}-SSL.key -out $certtools_home/staging/${line}/${line}-SSL.req -subj "$SubjectPrefix=*.${line#*.}"

		# Now sign the certs
		openssl x509 -sha256 -req -in $certtools_home/staging/${line}/${line}-SSL.req -CA $certtools_home/staging/authority/authority.crt -CAkey $certtools_home/staging/authority/authority.key  -extfile $certtools_home/conf/v3.ext -days 1826 -outform PEM -out $certtools_home/staging/${line}/${line}-SSL.crt

		# Create PKCS12 keystores
		openssl pkcs12 -export -in $certtools_home/staging/${line}/${line}-SSL.crt -inkey $certtools_home/staging/${line}/${line}-SSL.key -out $certtools_home/staging/${line}/${line}-SSL.p12 -name ${line#*.} -password pass:$masterPassword

		# Import P12 keystore into JKS
		$JAVA_HOME/bin/keytool -importkeystore -deststorepass $masterPassword -destkeypass $masterPassword  -destkeystore $certtools_home/staging/${line}/${line}.jks -srckeystore $certtools_home/staging/${line}/${line}-SSL.p12 -srcstoretype PKCS12 -srcstorepass $masterPassword -alias ${line#*.}

		# Import P12 keystore into JCES
		$JAVA_HOME/bin/keytool -importkeystore -deststorepass $masterPassword -destkeypass $masterPassword  -destkeystore $certtools_home/staging/${line}/${line}.jceks -deststoretype jceks -srckeystore $certtools_home/staging/${line}/${line}-SSL.p12 -srcstoretype PKCS12 -srcstorepass $masterPassword -alias ${line#*.}

		# Import the trust CA chain JKS
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line#*.}-SSL -file $certtools_home/staging/${line}/${line}-SSL.crt -keystore $certtools_home/staging/trust.jks -storepass $masterPassword

		# Import the trust CA chain JCEKS
		$JAVA_HOME/bin/keytool -import -noprompt -trustcacerts -alias ${line#*.}-SSL -file $certtools_home/staging/${line}/${line}-SSL.crt -storetype jceks -keystore $certtools_home/staging/trust.jceks -storepass $masterPassword

		# Update trust.p12
  rm $certtools_home/staging/trust.p12
  $JAVA_HOME/bin/keytool -importkeystore -deststorepass $masterPassword -destkeystore $certtools_home/staging/trust.p12 -deststoretype PKCS12 -srckeystore $certtools_home/staging/trust.jks -srcstorepass $masterPassword

 rm $certtools_home/staging/${line}/*.req
 cp -rf $certtools_home/staging/${line}/*.crt $certtools_home/target/public/servers
 cp -rf $certtools_home/staging/${line}/* $certtools_home/target/servers/${line}

		################  Server SSL  ###########
done <$certtools_home/conf/fqdn.conf
cp -rf $certtools_home/staging/trust.* $certtools_home/target/truststores
