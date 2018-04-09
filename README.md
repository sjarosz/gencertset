Git latest @ https://github.com/sjarosz/gencertset

1) Edit users.conf to add users that want p12 keypairs generated for.  These can be used for browsers or for web clients
2) Edit fqdn.conf to add in domain names for server certificates to be generated

four scripts:

1-BUILD-TRUSTSTORES 
If authority folder does not exists then generates new self-signed root-ca and loads into staging/trust.jks
In addition any truststores located in trusts folder are also added to this staging truststore.  For example creating a link to
current version JDK's public trust store will load those as well.  Example: ln -s $JAVA_HOME/jre/lib/security/cacerts trusts/public

2-GENERATE-SERVERS 
Looks at fqdn.conf and for every entry creates a javakeystore in the staging directory.  This javakeystore will contain a server certificate for SSL
****  Note this script may contain "not imported already exists messages"  This could be an OK situation where multiple FQDNs exist for same domain such as 
iam.example.com and mail.example.com  The reason is there is no need for multiple server certificates just client certificates in the same
truststore.   The CN of the domain certificates use wild card in form of *.example.com, so that multiple servers can share the same SSL alias.

3-GENERATE-USERS-AUTHN looks at user.conf and for every entry creates a pkcs (p12) keystore in the staging directory.  
This p12 file can be placed on web clients so they may use for their identity. 

4-ADD-PUBILC-TRUSTS Adds public trusts that are included in default JRE environment located in $JAVA_HOME/jre/lib/security/cacerts trusts/public into the trust stores that are being built.


If wish to generate a new CA trust certificae for SSL on all the certificates, delete the authority and staging folders prior to running these scripts.  
Otherwise the existing CA certificate in the staging/authority folder will continue to be used to sign additional certificates and the keystores and 
truststore will be appended to rather than replaced.


*note: Other than 1-BUILD-TRUSTSTORES scripts cannot be run unless an existing authority and staging are in place.  
ie. run 1-BUILD-TRUSTSTORES first unless appending with existing stores.


