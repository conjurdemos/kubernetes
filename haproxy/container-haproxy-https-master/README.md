A playground for different methods of TLS load balancing.

This is a little set of scripts to build a HTTPS load balancing example in docker, both terminating on the load balancer or on the backend servers. Uses NGINX and HAProxy, scripts do all the heavy lifting.

There's a couple of ways to do HTTPS termination:

* Terminate the connection on the load balancer, which does the HTTPS negotiation.
* Terminate the connection on the web servers and use the load balancer to fling packets.

The first one's easier for configuration, the second one can be more performant and tends to be easier to troubleshoot - it all depends on your environment.

# Interacting with this environment

2. `./rebuild.sh`, this does all the configuration of containers and builds configuration files.
	* Generates x509 certificates and keys, strips the passphrases and combines them into bundles
	* Creates a HAProxy configuration and confirms it's working
	* Tests the NGINX configuration files
3. `./start.sh` will start the containers and expose the ports.
4. `./stop.sh` will remove the docker containers when you're done.
5. `./cleanup.sh` will remove some temporary files.

There's three ports exposed by the load balancer:

* 8080 - this is a plaintext HTTP load balancer, for checking that the backend nodes are working.
* 8081 - HAProxy terminates SSL and forwards requests to the NGINX servers over plaintext HTTP
* 8082 - HAProxy forwards connections to the HTTPS-enabled NGINX servers, allowing them to terminate the HTTPS connection.

It's easiest to make requests with curl or something like that, given that we're working with self-signed certificates and weird/wonderful configurations.

This is an example of connecting to the third option, where the certificate is on the NGINX server. The response of "1" on the third-last line shows we were connected to NGINX server 1. Do the exact same thing again, you'll get "2" as (hopefully) you're running this in a test environment and the only ones using it.

	$ curl -kv https://192.168.99.100:8082
	* Rebuilt URL to: https://192.168.99.100:8082/
	*   Trying 192.168.99.100...
	* TCP_NODELAY set
	* Connected to 192.168.99.100 (192.168.99.100) port 8082 (#0)
	* TLS 1.2 connection using TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384
	* Server certificate: example.com
	> GET / HTTP/1.1
	> Host: 192.168.99.100:8082
	> User-Agent: curl/7.51.0
	> Accept: */*
	>
	< HTTP/1.1 200 OK
	< Server: NGINX/1.11.10
	< Date: Sat, 18 Feb 2017 11:07:48 GMT
	< Content-Type: text/html
	< Content-Length: 2
	< Last-Modified: Sat, 18 Feb 2017 05:33:39 GMT
	< Connection: keep-alive
	< ETag: "58a7dcb3-2"
	< Accept-Ranges: bytes
	<
	1
	* Curl_http_done: called premature == 0
	* Connection #0 to host 192.168.99.100 left intact

The troubleshooting test you can do is as follows (again, my docker machine is running on 192.168.99.100). This uses OpenSSL's handy s_client tool.

	$ echo "" | openssl s_client -connect 192.168.99.100:8081
	CONNECTED(00000003)
	depth=0 /C=AU/ST=Queensland/L=Town/O=Example Corp/OU=OrgUnit/CN=example.com/emailAddress=example@example.com
	verify error:num=20:unable to get local issuer certificate
	verify return:1
	depth=0 /C=AU/ST=Queensland/L=Town/O=Example Corp/OU=OrgUnit/CN=example.com/emailAddress=example@example.com
	verify error:num=21:unable to verify the first certificate
	verify return:1
	---
	Certificate chain
	 0 s:/C=AU/ST=Queensland/L=Town/O=Example Corp/OU=OrgUnit/CN=example.com/emailAddress=example@example.com
	   i:/C=AU/ST=Queensland/L=Town/O=Example Corp/OU=OrgUnit/CN=example.com/emailAddress=example@example.com
	---
	Server certificate
	-----BEGIN CERTIFICATE-----
	(SNIP)
	/pwFfv7BBJckodivT8aHWb4IyA4g/CjXzTVpvkZxp7aeJlr+PlL9Gmg=
	-----END CERTIFICATE-----
	subject=/C=AU/ST=Queensland/L=Town/O=Example Corp/OU=OrgUnit/CN=example.com/emailAddress=example@example.com
	issuer=/C=AU/ST=Queensland/L=Town/O=Example Corp/OU=OrgUnit/CN=example.com/emailAddress=example@example.com
	---
	No client certificate CA names sent
	---
	SSL handshake has read 1170 bytes and written 456 bytes
	---
	New, TLSv1/SSLv3, Cipher is AES256-SHA
	Server public key is 2048 bit
	Secure Renegotiation IS supported
	Compression: NONE
	Expansion: NONE
	SSL-Session:
		Protocol  : TLSv1
		Cipher    : AES256-SHA
		Session-ID: 31DD08853C606D71D29058B11A7814F4F9DDE4EC2F24DA7CEDA5D0CECB759A3D
		Session-ID-ctx:
		Master-Key: D96786B109A8D69F623EC3EDC33B4EF305AF3AF50F82D6E5BD3C9C7316D01566BEE1D0E6BAEB366AF14FEF356EEEE433
		Key-Arg   : None
		Start Time: 1487416417
		Timeout   : 300 (sec)
		Verify return code: 21 (unable to verify the first certificate)

Well, that was long! I've snipped out most of the certificate, since that's generated when you build the environment. The important part is that because port 8081 is the one where SSL terminates on the HAProxy instance, you'll get the same certificate every time. Try it a few times and see.

OpenSSL s_client is like the SSL version of telnet. Obviously there's a lot more configuration options and output, but if you just want to do some basic testing, `openssl s_client -connect ip:port` will get you a long way. Throw `-servername example.com` on the end and you'll test SNI, a topic for another time.

The `echo "" |` part of the command is us throwing something at the server to make it drop the connection.

If you do the test multiple times against port 8082, you'll get different certificates each time because you're connecting in a round-robin method to the two NGINX servers, and their certificates are generated based on different keys - even if they're the same otherwise.
