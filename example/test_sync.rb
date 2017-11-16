require "redis_rpc"


client = RedisRpc::Client.new("redis://127.0.0.1:6379/0", "pub_channel", "sub_channel")


secret_client = RedisRpc::Client.new("redis://127.0.0.1:6379/0", "secret_pub_channel", "secret_sub_channel", secret_key: "43468eeb-035e-4653-9a67-f200d1592faf")


def run(client)
  sleep 3
  (1..30).each { |i| puts i, client.get_current_time.sync }
end

run(client)
run(secret_client)
