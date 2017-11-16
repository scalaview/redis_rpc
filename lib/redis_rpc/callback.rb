module RedisRpc

  class Callback

    def initialize
      @funs = {}
    end

    def exec_callback(args)
      _args = JSON.parse(args, symbolize_names: true)
      # {uuid: uuid, _method: method, result: result}
      callback = @funs.delete _args[:uuid]
      callback.call(_args[:result]) if !callback.nil?
    end

    def push(uuid, callback)
      @funs[uuid] = callback
    end

  end
end