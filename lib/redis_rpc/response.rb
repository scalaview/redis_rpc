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
      # SyncHandler.new(@redis, request[:uuid])
    end

    def catch(uuid, e)
      @logger.error("#{uuid}: #{e}")
      @redis.publish(@channel, {uuid: uuid, error: e}.to_json)
    end

    def sync_callback(args, timeout=30)
      begin
        _args = JSON.parse(args, symbolize_names: true)
        @logger.error(ArgumentError.new("miss method uuid")) and return if _args[:uuid].nil?
        # {uuid: uuid, _method: method, result: result, error: error}
        @redis.lpush(_args[:uuid], _args.to_json)
        @redis.expire(_args[:uuid], timeout)
      rescue Exception => e
        @logger.error(e)
      end
    end

  end

  class SyncHandler

    def initialize(redis, uuid, timeout=30)
      @redis = redis
      @uuid = uuid
      @timeout = timeout
    end

    def sync
      uuid, result = @redis.blpop(@uuid, :timeout => @timeout)
      if uuid.nil?
        raise(Timeout::Error.new("wait for timeout"))
      else
        _args = JSON.parse(result, symbolize_names: true)
        if !_args[:result].nil?
          return _args[:result]
        elsif !_args[:error].nil?
          raise(Timeout::Error.new(_args[:error]))
        end
      end

    end

  end

end