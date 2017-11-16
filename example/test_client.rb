require "redis_rpc"

client = RedisRpc::Client.new("redis://127.0.0.1:6379/0", "pub_channel", "sub_channel")


def run(client)
  sleep 3
  (1..30).each { |i| client.get_current_time{|time| puts time} }
end

run(client)

sleep 1
