#!/bin/bash
# cleans up leftover stuff so that I can push it to git easier

if [ -d ssl/ ]
	then
	echo "Removing ssl/"
	rm -rf ssl/
	fi
if [ -f haproxy/haproxy.cfg ]
	then
	echo "Removing haproxy.cfg"
	rm haproxy/haproxy.cfg
	fi
if [ -f openssl.cfg ]
	then
	"Removing openssl.cfg"
	rm openssl.cfg
	fi

