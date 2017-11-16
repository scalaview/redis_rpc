require 'redis'
require 'logger'
require 'securerandom'
require "redis_rpc/response.rb"
require "redis_rpc/callback.rb"

module RedisRpc

  class Client

    def initialize(url, sub_channel, pub_channel, level: Logger::WARN)
      @redis = Redis.new(url: url)
      @sub_channel = sub_channel
      @pub_channel = pub_channel
      @res = Response.new(Redis.new(url: url), pub_channel, init_log(level))
      @callback = Callback.new(init_log(level))
      exec
    end

    def exec
      @thread = Thread.new do
        begin
          @redis.subscribe(@sub_channel) do |on|
            on.subscribe do |channel, subscriptions|
              @logger.info("Subscribed to ##{channel} (#{subscriptions} subscriptions)")
            end

            on.message do |channel, args|
              @logger.info("##{channel}: #{args}")
              begin
                _args = JSON.parse(args, symbolize_names: true)
                @logger.error(ArgumentError.new("miss method uuid")) and return if _args[:uuid].nil?
                @callback.exec_callback(_args)
                @res.sync_callback(_args)
              rescue Exception => e
                @logger.error(e)
              end
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

    def method_missing(m, *args, &block)
      request = {
        method: m,
        params: args,
        uuid: SecureRandom.uuid
      }
      @callback.push(request[:uuid], block) if !block.nil?
      @res.publish(request)
    end

  end

end