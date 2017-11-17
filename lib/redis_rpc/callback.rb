require "redis_rpc/error.rb"

module RedisRpc

  class Callback

    def initialize(logger)
      @logger = logger
      @funs = {}
    end

    def exec_callback(args)
      begin
        # {uuid: uuid, _method: method, result: result, error: error}
        callback = @funs.delete args[:uuid]
        if !callback.nil?
          callback.call(args[:error].nil? ? nil : FunctionCallbackError.new(args[:error]), args[:result])
          true
        end
      rescue Exception => e
        @logger.error(e)
      end
    end

    def push(uuid, callback)
      @funs[uuid] = callback
    end

  end
end