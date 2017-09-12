FROM conjur-appliance:4.9-stable

ENV AUTHN_K8S_VERSION 0.2.0.0-91ac501

COPY conjur-authn-k8s_${AUTHN_K8S_VERSION}_amd64.deb /tmp

RUN dpkg -i /tmp/conjur-authn-k8s_${AUTHN_K8S_VERSION}_amd64.deb

RUN rm /etc/service/conjur/authn-k8s/down

# Disable regeneration of dhparams, which is very CPU intensive.
RUN cat /etc/ssl/dh-3072-rfc3526.pem | grep -v BOOTSTRAP > /etc/ssl/dhparam.pem

ENV TERM xterm

COPY conjur.json /etc/
