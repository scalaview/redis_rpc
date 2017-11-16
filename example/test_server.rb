require "redis_rpc"
class TimeServer

  def get_current_time
    return Time.now
  end

end

rps = RedisRpc::Server.new("redis://127.0.0.1:6379/0", "sub_channel", "pub_channel", TimeServer.new, standalone: false)