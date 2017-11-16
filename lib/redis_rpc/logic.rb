require "redis_rpc/response.rb"
module RedisRpc

    class Logic

      attr_accessor :res

      def initialize(url, callback, channel)
        @redis = Redis.new(url: url)
        @res = Response.new(@redis, channel)
        @callback = callback
      end

      def exec(args)
        begin
          _args = JSON.parse(args, symbolize_names: true)
          raise(ArgumentError, "miss callback uuid")  if _args[:uuid].nil?
          raise(ArgumentError, "miss method name")  if _args[:method].nil?

          result = @callback.send(_args[:method], *_args[:params])
          @res.publish({uuid: _args[:uuid], _method: _args[:method], result: result})
        rescue Exception => e
          @res.catch(e)
        end
      end
  end

end