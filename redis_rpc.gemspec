Gem::Specification.new do |s|
  s.name        = 'redis_rpc'
  s.version     = '0.0.3'
  s.date        = '2017-11-16'
  s.summary     = 'redis rpc'
  s.description = "use redis sub/pub work as rpc"
  s.authors     = ["benko"]
  s.email       = 'benko.b@shopperplus.com'
  s.files       = ["lib/redis_rpc.rb", "lib/redis_rpc/callback.rb", "lib/redis_rpc/client.rb", "lib/redis_rpc/error.rb", "lib/redis_rpc/logic.rb",  "lib/redis_rpc/parser.rb", "lib/redis_rpc/response.rb", "lib/redis_rpc/server.rb", "lib/redis_rpc/version.rb"]
  s.require_paths = ["lib"]
end