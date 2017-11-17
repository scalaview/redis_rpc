require "redis_rpc/callback.rb"
require "redis_rpc/client.rb"
require "redis_rpc/logic.rb"
require "redis_rpc/response.rb"
require "redis_rpc/server.rb"
require "redis_rpc/version.rb"

module RedisRpc

  EXCEPTION_CHANNEL = :redis_rpc_exception

  class  << self

    # Create a new server instance
    #
    # @param [String] :url (value of the environment variable REDIS_URL) a Redis URL, for a TCP connection: `redis://:[password]@[hostname]:[port]/[db]` (password, port and database are optional), for a unix socket connection: `unix://[path to Redis socket]`. This overrides all other options.
    # @param [String] :sub_channel a channel to listen.
    # @param [String] :pub_channel a channel to publish.
    # @param [Object] :front_object The object that handles requests on the server.
    # @option options [Logger::] :level (Logger::WARN) Logger options.
    # @option options [Boolean] :standalone (true) set true if use a thread to handle this server.
    # @option options [String] :secret_key (nil) set a long String greater than 16 when you want to encryt the data.
    # @option options [Float] :timeout (10.0) timeout in seconds

    def server(*args)
      RedisRpc::Server.new *args
    end

    # Create a new client instance
    #
    # @param [String] :url (value of the environment variable REDIS_URL) a Redis URL, for a TCP connection: `redis://:[password]@[hostname]:[port]/[db]` (password, port and database are optional), for a unix socket connection: `unix://[path to Redis socket]`. This overrides all other options.
    # @param [String] :sub_channel a channel to listen.
    # @param [String] :pub_channel a channel to publish.
    # @option options [Logger::] :level (Logger::WARN) Logger options.
    # @option options [String] :secret_key (nil) set a long String greater than 16 when you want to encryt the data.
    # @option options [Float] :timeout (10.0) timeout in seconds

    def client(*args)
      RedisRpc::Client.new *args
    end

  end

end