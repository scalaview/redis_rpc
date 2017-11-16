## Usage

### Server

Use as dRuby

```ruby
require "redis_rpc"

class TimeServer

  def get_current_time
    return Time.now
  end

end

rps = RedisRpc::Server.new("redis://127.0.0.1:6379/0", "sub_channel", "pub_channel", TimeServer.new, level: Logger::WARN, standalone: false)

```

level: defualt is Logger::WARN. If use on Rails, logger level set as same as Rails.logger.
standalone: defualt is true that will create a thread to handle this server.

### Client

```ruby
client = RedisRpc::Client.new("redis://127.0.0.1:6379/0", "pub_channel", "sub_channel")

```

Be careful two channel on client is opposite of server.

### call server method as DRb

```ruby
client.get_current_time{|time| puts time}
```

The result will return in the block you give. The return value only support callback.
