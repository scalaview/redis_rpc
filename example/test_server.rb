require "redis_rpc"
class TimeServer

  def get_current_time
    return Time.now
  end

end

secret_rps = RedisRpc.server("redis://127.0.0.1:6379/0", "secret_sub_channel", "secret_pub_channel", TimeServer.new, standalone: true, secret_key: "43468eeb-035e-4653-9a67-f200d1592faf", timeout: 3)

rps = RedisRpc::Server.new("redis://127.0.0.1:6379/0", "sub_channel", "pub_channel", TimeServer.new, standalone: false)