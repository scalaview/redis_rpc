require 'json'
module RedisRpc

  class Response

    def initialize(redis, channel, logger)
      @redis = redis
      @channel = channel
      @logger = logger
    end

    def publish(request)
      @redis.publish(@channel, request.to_json)
    end

    def catch(uuid, e)
      @logger.error("#{uuid}: #{e}")
      @redis.publish(@channel, {uuid: uuid, error: e}.to_json)
    end

  end

end