require 'redis'
require 'logger'
require "redis_rpc/client.rb"
require "redis_rpc/version.rb"
require "redis_rpc/logic.rb"
require "redis_rpc/parser.rb"

module RedisRpc

  class Server

    def initialize(url, sub_channel, pub_channel, front_object, level: Logger::WARN, standalone: true, secret_key: nil, timeout: 10.0)
      @redis = Redis.new(url: url)
      @sub_channel = sub_channel
      @pub_channel = pub_channel
      @level = level
      @timeout = timeout
      @parser = Parser.new(secret_key)
      @logic = Logic.new(url, front_object, pub_channel, init_log(level), @parser)
      standalone ? standalone_exec : exec
    end

    def standalone_exec
      @thread = Thread.new do
        exec
      end
    end

    def exec
      begin
        @redis.subscribe(@sub_channel) do |on|
          on.subscribe do |channel, subscriptions|
            @logger.info("Subscribed to ##{channel} (#{subscriptions} subscriptions)")
          end

          on.message do |channel, args|
            @logger.info("##{channel}: #{args}") if @level <= Logger::INFO
            @logic.exec(args, @timeout)
          end
          on.unsubscribe do |channel, subscriptions|
            @logger.info("Unsubscribed from ##{channel} (#{subscriptions} subscriptions)")
          end
        end
      rescue Redis::BaseConnectionError => error
        @logger.error("#{error}, retrying in 30s")
        sleep 30
        retry
      end
    end

    def init_log(level)
      if defined?(Rails)
        @logger = Rails.logger
      else
        require 'logger'
        @logger = ::Logger.new(STDOUT)
        @logger.level = level
      end
      @logger
    end

  end

end
