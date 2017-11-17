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

server = RedisRpc.server("redis://127.0.0.1:6379/0", "secret_sub_channel", "secret_pub_channel", TimeServer.new, standalone: false, secret_key: "43468eeb-035e-4653-9a67-f200d1592faf", timeout: 3)

```

level: defualt is Logger::WARN. If use on Rails, logger level set as same as Rails.logger.
standalone: defualt is true that will create a thread to handle this server.

### Client

```ruby
client = RedisRpc.client("redis://127.0.0.1:6379/0", "secret_pub_channel", "secret_sub_channel", secret_key: "43468eeb-035e-4653-9a67-f200d1592faf", timeout: 3)

```

Be careful two channel on client is opposite of server.

### call server method as DRb async

```ruby
client.get_current_time{|err, time| puts time}
```

The result will return in the block you give. And the first one is the error if the function rescue it. The return value only support callback.


### call server method as DRb sync

```ruby
client.get_current_time.sync
```

The result wait until return.