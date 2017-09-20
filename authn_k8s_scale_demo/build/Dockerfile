FROM ubuntu:16.04

RUN apt-get update && apt-get install -y curl

RUN curl -o conjur.deb -L https://github.com/conjurinc/cli-ruby/releases/download/v5.4.0/conjur_5.4.0-1_amd64.deb \
  && dpkg -i conjur.deb \
  && rm conjur.deb

RUN mkdir -p /usr/local/lib/summon

WORKDIR /tmp/

COPY summon-linux-amd64.tar.gz .
COPY summon-conjur-linux-amd64.tar.gz .

RUN tar xzf /tmp/summon-linux-amd64.tar.gz && mv summon /usr/local/bin/
RUN tar xzf /tmp/summon-conjur-linux-amd64.tar.gz && mv summon-conjur /usr/local/lib/summon/

WORKDIR /

COPY secrets.yml .
COPY copy-summon.sh .
COPY authenticator.rb .
COPY webapp.rb .
COPY webapp.sh .
