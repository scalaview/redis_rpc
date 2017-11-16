require 'json'
module RedisRpc

  class Response

    def initialize(redis, channel)
      @redis = redis
      @channel = channel
    end

    def publish(request)
      @redis.publish(@channel, request.to_json)
    end

    def catch(e)
      publish(RedisRpc::EXCEPTION_CHANNEL, e.message.to_s)
    end

    def method_missing(m, *args)
      publish(m, args)
    end

  end

end