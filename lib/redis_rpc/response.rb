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
    end

    def publish(request, timeout)
      request_str = @parser.pack(request.to_json)
      @redis.publish(@channel, request_str)
      @sync_handlers[request[:uuid]] = SyncHandler.new(@parser.secret_key, request[:method], timeout)
      Thread.new(@sync_handlers, request[:uuid], timeout) {|handlers, uuid, t| sleep(t+3);  handlers.delete(uuid) }
      @sync_handlers[request[:uuid]]
    end

    def sync_callback(args)
      # {uuid: uuid, _method: method, result: result, error: error}
      unless (sync_handler = @sync_handlers.delete(args[:uuid])).nil?
        sync_handler.release(args)
      end
    end

    def catch(uuid, e)
      @logger.error("#{uuid}: #{e}")
      request_str = @parser.pack({uuid: uuid, error: e}.to_json)
      @redis.publish(@channel, request_str)
    end

  end

  class SyncHandler

    def initialize(secret_key, _method, timeout=10)
      @parser = Parser.new(secret_key)
      @_method = _method
      @timeout = timeout
      @lock = Mutex.new
      @condition = ConditionVariable.new
    end

    def sync
      @lock.synchronize { @condition.wait(@lock, @timeout) }
      if @response.nil?
        raise(Timeout::Error.new("method: #{@_method} wait for timeout #{@timeout}s"))
      elsif !@response[:result].nil?
        return @response[:result]
      elsif !@response[:error].nil?
        raise(FunctionCallbackError.new(@response[:error]))
      end
    end

    def release(res)
      @response = res
      @lock.synchronize { @condition.signal }
    end

  end

end