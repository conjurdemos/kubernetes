#!/opt/conjur/embedded/bin/ruby

require 'conjur-api'
require 'restclient'
require 'json'

Conjur.configuration.apply_cert_config!

token_filename = "/run/conjur/access-token"
while !File.exists?(token_filename)
  $stderr.puts "Waiting for #{token_filename} to exist"
  sleep 2
end

variable_id = "db/password"

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
