require "redis_rpc/response.rb"
module RedisRpc

    class Logic

      attr_accessor :res

      def initialize(url, callback, channel, logger, parser)
        @redis = Redis.new(url: url)
        @logger = logger
        @res = Response.new(@redis, channel, logger, parser)
        @callback = callback
        @parser = parser
      end

      def exec(args, timeout)
        begin
          _args = @parser.parse(args)
          logger.error(ArgumentError.new("miss method name or uuid")) and return if _args[:uuid].nil? || _args[:method].nil?

          result = @callback.send(_args[:method], *_args[:params])
          @res.publish({uuid: _args[:uuid], _method: _args[:method], result: result}, timeout)
        rescue Exception => e
          if defined?(_args) && !_args.nil?
            @res.catch(_args[:uuid], e)
          else
            @logger.error(e)
          end
        end
      end

  end

end