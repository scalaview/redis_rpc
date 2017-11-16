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
      @res = Response.new(Redis.new(url: url), pub_channel)
      @callback = Callback.new
      init_log(level)
      exec
    end

    def exec
      @thread = Thread.new do
        begin
          @redis.subscribe(@sub_channel, RedisRpc::EXCEPTION_CHANNEL) do |on|
            on.subscribe do |channel, subscriptions|
              @logger.info("Subscribed to ##{channel} (#{subscriptions} subscriptions)")
            end

            on.message do |channel, args|
              @logger.info("##{channel}: #{args}")
              case channel.to_sym
              when RedisRpc::EXCEPTION_CHANNEL
                @logger.error("exception: #{args}")
              else
                begin
                  @callback.exec_callback(args)
                rescue Exception => e
                  @logger.error(e.message.to_s)
                end
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
      @callback.push(request[:uuid], block)
      @res.publish(request)
    end

  end




end