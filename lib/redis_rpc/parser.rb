require 'openssl'
require "base64"

module RedisRpc

  class Parser

    attr_accessor :secret_key

    def initialize(secret_key)
      @secret_key = secret_key
      @aes = Base64Aes.new(@secret_key) if !@secret_key.nil?
    end

    def parse(args)
      args = @aes.decrypt(args) if !@secret_key.nil?
      _args = JSON.parse(args, symbolize_names: true)
    end

    def pack(args)
      args = @aes.encrypt(args) if !@secret_key.nil?
      args
    end

  end

  class Base64Aes
    def initialize(key)
      @key = key
      @cipher = OpenSSL::Cipher::AES.new(128, :CBC).encrypt
      @decipher = OpenSSL::Cipher::AES.new(128, :CBC).decrypt
    end
    def encrypt(data)
      @cipher.key = @key
      encode64(@cipher.update(data) + @cipher.final)
    end
    def decrypt(encrypted)
      @decipher.key = @key
      @decipher.update(decode64(encrypted)) + @decipher.final
    end
    private
    def encode64(str)
      Base64.strict_encode64 str
    end
    def decode64(str)
      Base64.strict_decode64 str
    end
  end

end