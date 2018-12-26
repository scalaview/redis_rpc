require "redis_rpc/response.rb"
module RedisRpc

  class Logic

    attr_accessor :res

    def initialize(url, callback, channel, logger, parser)
      @logger = logger
      @res = ClientResponse.new(Redis.new(url: url), channel, logger, parser)
      @callback = callback
      @parser = parser
    end

    def exec(args, timeout)
      Thread.new do
        begin
          _args = @parser.parse(args)
          @logger.error(ArgumentError.new("miss method name or uuid")) and return if _args[:uuid].nil? || _args[:method].nil?
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
    rescue Exception => e
      @logger.error(e)
    end

  end

  class ClientResponse < Response

    def publish(request, timeout)
      request_str = @parser.pack(request.to_json)
      @redis.publish(@channel, request_str)
    end

  end

end