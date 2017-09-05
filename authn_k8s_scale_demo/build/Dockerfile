FROM ubuntu:16.04

RUN apt-get update && apt-get install -y curl

RUN curl -o conjur.deb -L https://github.com/conjurinc/cli-ruby/releases/download/v5.4.0/conjur_5.4.0-1_amd64.deb \
  && dpkg -i conjur.deb \
  && rm conjur.deb

WORKDIR /

COPY authenticator.rb .
COPY webapp.rb .

