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
      @sync_handlers = {}
      # 需要缓存整个SyncHandler
    end

    def publish(request, timeout)
      request_str = @parser.pack(request.to_json)
      @redis.publish(@channel, request_str)
      @sync_handlers[request[:uuid]] = SyncHandler.new(@redis, request[:method], @parser, timeout)
      @sync_handlers[:uuid]
    end

    def sync_callback(args, timeout=5)
      # {uuid: uuid, _method: method, result: result, error: error}
      # @redis.set(args[:uuid], @parser.pack(args.to_json))
      # @redis.expire(args[:uuid], timeout.to_i)
      @sync_handlers[args[:uuid]].release(args) unless @sync_handlers[args[:uuid]].nil?
    end

    def catch(uuid, e)
      @logger.error("#{uuid}: #{e}")
      request_str = @parser.pack({uuid: uuid, error: e}.to_json)
      @redis.publish(@channel, request_str)
    end

  end

  class SyncHandler

    SLEEP_TIME = 0.01
    attr_accessor :response, :lock, :condition

    def initialize(redis, _method, parser, timeout=30)
      @redis = redis
      @_method = _method
      @expires_at = Time.now + timeout
      # @parser = Parser.new(secret_key)
      @parser = parser
      @lock = Mutex.new
      @condition = ConditionVariable.new
    end

    # def sync
    #   while Time.now <= @expires_at
    #     result = @redis.get(@uuid)
    #     if !result.nil?
    #       @redis.del(@uuid)
    #       _args = @parser.parse(result)
    #       if !_args[:result].nil?
    #         return _args[:result]
    #       elsif !_args[:error].nil?
    #         raise(FunctionCallbackError.new(_args[:error]))
    #       end
    #     end
    #     sleep SLEEP_TIME
    #   end
    #   raise(Timeout::Error.new("method: #{@_method} wait for timeout"))
    # end

    def sync
      lock.synchronize { condition.wait(lock) }
      response
    end

    def release(res)
      response = res
      lock.synchronize { condition.signal }
    end

  end

end