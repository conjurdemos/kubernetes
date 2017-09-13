#!/opt/conjur/embedded/bin/ruby

require 'conjur-api'
require 'conjur-cli'
require 'restclient'
require 'json'

# Configure Conjur connection.
# Keep the access token fresh and available to the application container.

Conjur.configuration.apply_cert_config!
Conjur.log = $stderr
filename = "/run/conjur/access-token"

def authenticate
  # Lookup the client API key
  raise "Expecting CONJUR_AUTHN_API_KEY to be blank" if ENV['CONJUR_AUTHN_API_KEY']
  username = ENV['CONJUR_AUTHN_LOGIN'] or raise "No CONJUR_AUTHN_LOGIN"
  api_key = ENV['CONJUR_CLIENT_API_KEY'] or raise "No CONJUR_CLIENT_API_KEY"
  api_key = api_key.strip

  # Use the client API key to get an access token for the authn-k8s client.
  authn_url = Conjur.configuration.authn_url
  credentials = begin
    Conjur.configuration.authn_url = "#{Conjur.configuration.appliance_url}/authn"
    Conjur::API.new_from_key('host/conjur/authn-k8s/minikube/default/client', api_key).credentials
  ensure
    Conjur.configuration.authn_url = authn_url
  end

  JSON::parse(RestClient::Resource.new(Conjur.configuration.authn_url, credentials)["users/#{CGI.escape username}/authenticate"].post("dummy", content_type: 'text/plain')).tap do |token|
    puts "Authenticated as #{token['data'].inspect}"
  end
end

while true
  begin
    token = authenticate
    File.write(filename, token.to_json)
  rescue
    $stderr.puts $!
  end
  sleep 10
end
