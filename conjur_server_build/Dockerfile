FROM conjur-appliance:4.9-stable

COPY conjur-authn-k8s-0.2.0_amd64.deb /tmp

RUN dpkg -i /tmp/conjur-authn-k8s-0.2.0_amd64.deb

RUN rm /etc/service/conjur/authn-k8s/down
