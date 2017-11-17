require 'json'
require "redis_rpc/error.rb"
require "redis_rpc/parser.rb"

module RedisRpc

  class Response

    def initialize(redis, channel, logger, parser)
      @redis = redis
      @channel = channel
      @logger = logger
      @parser = parser
    end

    def publish(request, timeout)
      request_str = @parser.pack(request.to_json)
      @redis.publish(@channel, request_str)
      SyncHandler.new(@redis, request[:uuid], request[:method], @parser.secret_key, timeout)
    end

    def sync_callback(args, timeout=5)
        # {uuid: uuid, _method: method, result: result, error: error}
        @redis.set(args[:uuid], @parser.pack(args.to_json))
        @redis.expire(args[:uuid], timeout.to_i)
    end

    def catch(uuid, e)
      @logger.error("#{uuid}: #{e}")
      publish({uuid: uuid, error: e})
    end

  end

  class SyncHandler

    SLEEP_TIME = 0.1

    def initialize(redis, uuid, _method, secret_key, timeout=30)
      @redis = redis
      @uuid = uuid
      @_method = _method
      @expires_at = Time.now + timeout
      @parser = Parser.new(secret_key)
    end

    def sync
      while Time.now <= @expires_at
        result = @redis.get(@uuid)
        if !result.nil?
          @redis.del(@uuid)
          _args = @parser.parse(result)
          if !_args[:result].nil?
            return _args[:result]
          elsif !_args[:error].nil?
            raise(FunctionCallbackError.new(_args[:error]))
          end
        end
        sleep SLEEP_TIME
      end
      raise(Timeout::Error.new("method: #{@_method} wait for timeout"))
    end

  end

end