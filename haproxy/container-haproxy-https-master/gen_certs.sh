#!/bin/bash
# generates certificates, really messy part of the build script so it's been broken out

rm -rf ssl/*
mkdir -p ssl/1/ ssl/2/ ssl/certHA/

# information on how SANs work - http://blog.endpoint.com/2014/10/openssl-csr-with-alternative-names-one.html

f() {
	echo ""
	echo "Generating Certificate $@.."
	FOLDER="ssl/$@"
	openssl req -newkey rsa:2048 -extensions req_ext -keyout $FOLDER/cert.key -out $FOLDER/cert.crt -x509 -config openssl.cfg  -outform PEM
	openssl rsa -in $FOLDER/cert.key -out $FOLDER/cert.key -passin pass:example
	cat $FOLDER/cert* >> $FOLDER/cert.pem
}

echo ""
echo "Generating openssl.cfg..."
cat > openssl.cfg <<-EOF
[ req ]
prompt				= no
output_password		= "example"
default_bits		= 2048
distinguished_name	= req_distinguished_name
extensions 			= req_ext
req_extensions		= req_ext

[ req_ext ]
basicConstraints	= CA:FALSE
keyUsage			= nonRepudiation, digitalSignature, keyEncipherment
subjectAltName		= @alt_names

[ req_distinguished_name ]
C	= AU
ST	= Queensland
L	= Town
O	= Example Corp
OU	= OrgUnit
CN	= example.com
emailAddress	= example@example.com

[alt_names]
DNS.1  	= example.com
IP.1 	= $(cat docker_ip.cfg)
EOF

echo "Done."

f "1"
f "2"
f "certHA"

echo ""
echo "Deleting openssl config"
rm openssl.cfg
