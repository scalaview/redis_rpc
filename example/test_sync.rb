require "redis_rpc"

client = RedisRpc::Client.new("redis://127.0.0.1:6379/0", "pub_channel", "sub_channel")


def run(client)
  sleep 3
  (1..30).each { |i| puts i, client.get_current_time.sync }
end

run(client)
