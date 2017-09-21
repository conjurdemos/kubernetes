#!/opt/conjur/embedded/bin/ruby

require 'conjur-api'
require 'restclient'
require 'json'

Conjur.configuration.apply_cert_config!

$token_filename = token_filename = "/run/conjur/access-token"
while !File.exists?(token_filename)
  $stderr.puts "Waiting for #{token_filename} to exist"
  sleep 2
end

variable_id = "db/password"

Thread.new do
  while true
    api = Conjur::API.new_from_token JSON.parse(File.read(token_filename))
    begin
      password = api.variable(variable_id).value
      puts "Database password : #{password}"
      $stdout.flush
    rescue RestClient::ResourceNotFound
      puts $!
      $stderr.puts "Value for #{variable_id.inspect} was not found. Is the variable created, and is the secret value added?"
    end
    sleep 5
  end
end

require 'sinatra'
require 'webrick/https'

class WebappServer < Sinatra::Base

  enable :logging

  helpers do
    def conjur_api
      Conjur::API.new_from_token JSON.parse(File.read($token_filename))
    end
  end

  get '/' do
    begin
      password = conjur_api.variable("db/password").value
      "DB password: #{password}"
    rescue
      $stderr.puts $!
      $stderr.puts $!.backtrace.join("\n")
      halt 500, "Error: #{$!}"
    end
  end
end

CERT_PATH = '/etc/conjur/ssl'

webrick_options = {
  :Port               => 443,
  :Logger             => WEBrick::Log::new($stderr, WEBrick::Log::DEBUG),
  :SSLEnable          => true,
  :SSLVerifyClient    => OpenSSL::SSL::VERIFY_NONE,
  :SSLCertificate     => OpenSSL::X509::Certificate.new(  File.open(File.join(CERT_PATH, "client.pem")).read),
  :SSLPrivateKey      => OpenSSL::PKey::RSA.new(          File.open(File.join(CERT_PATH, "client.key")).read),
  :app                => WebappServer
}

Rack::Server.start webrick_options
