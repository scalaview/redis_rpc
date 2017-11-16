require 'json'
require "redis_rpc/error.rb"

module RedisRpc

  class Response

    def initialize(redis, channel, logger)
      @redis = redis
      @channel = channel
      @logger = logger
    end

    def publish(request)
      @redis.publish(@channel, request.to_json)
      SyncHandler.new(@redis, request[:uuid])
    end

    def sync_callback(args, timeout=30)
        # {uuid: uuid, _method: method, result: result, error: error}
        @redis.set(args[:uuid], args.to_json)
        @redis.expire(args[:uuid], timeout)
    end

    def catch(uuid, e)
      @logger.error("#{uuid}: #{e}")
      @redis.publish(@channel, {uuid: uuid, error: e}.to_json)
    end

  end

  class SyncHandler

    SLEEP_TIME = 0.1


    def initialize(redis, uuid, timeout=30)
      @redis = redis
      @uuid = uuid
      @expires_at = Time.now + timeout
    end

    def sync
      while true
        result = @redis.get(@uuid)
        if !result.nil?
          @redis.del(@uuid)
          _args = JSON.parse(result, symbolize_names: true)
          if !_args[:result].nil?
            return _args[:result]
          elsif !_args[:error].nil?
            raise(FunctionCallbackError.new(_args[:error]))
          end
        end
        if Time.now > @expires_at
          raise(Timeout::Error.new("method: #{_args[:method]} wait for timeout"))
        end
        sleep SLEEP_TIME
      end
    end

  end

end