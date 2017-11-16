module RedisRpc

  class Callback

    def initialize(logger)
      @logger = logger
      @funs = {}
    end

    def exec_callback(args)
      begin
        _args = JSON.parse(args, symbolize_names: true)
        @logger.error(ArgumentError.new("miss method uuid")) and return if _args[:uuid].nil?
        # {uuid: uuid, _method: method, result: result, error: error}
        callback = @funs.delete _args[:uuid]
        callback.call(_args[:error], _args[:result]) if !callback.nil?
      rescue Exception => e
        @logger.error(e)
      end
    end

    def push(uuid, callback)
      @funs[uuid] = callback
    end

  end
end