#!/opt/conjur/embedded/bin/ruby

require 'conjur-api'
require 'restclient'
require 'openssl'
require 'json'

# Configure Conjur connection.
# Keep the access token fresh and available to the application container.

Conjur.configuration.apply_cert_config!
Conjur.log = $stderr
filename = "/run/conjur/access-token"

def username
  ENV['CONJUR_AUTHN_LOGIN'] or raise "No CONJUR_AUTHN_LOGIN"
end

def login
  RestClient::Resource.new(Conjur.configuration.authn_url, user: username, password: "x")["users/login"].get
end

def decrypt_token token
  key = OpenSSL::PKey::RSA.new(File.read("/etc/conjur/ssl/client.key"))
  cert = OpenSSL::X509::Certificate.new(File.read("/etc/conjur/ssl/client.pem"))
  decryptor = OpenSSL::PKCS7.new token
  decryptor.decrypt key, cert
end

def authenticate
  pkcs7 = RestClient::Resource.new(Conjur.configuration.authn_url)["users/#{CGI.escape username}/authenticate"].post("dummy", content_type: 'text/plain')
  JSON::parse(decrypt_token(pkcs7))
end

login

while true
  begin
    token = authenticate
    File.write(filename, token.to_json)
  rescue
    $stderr.puts $!
  end
  sleep 10
end
