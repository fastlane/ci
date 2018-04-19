require "openssl"
require_relative "logging_module"

module FastlaneCI
  # makes encrypting string as easy as ijFkpReUM6kLfvry0A78cQ==
  class StringEncrypter
    class << self
      include FastlaneCI::Logging
    end

    def self.default_key
      @_key ||= Digest::SHA256.digest(FastlaneCI.dot_keys.encryption_key)
    end

    def self.encode(string, key: StringEncrypter.default_key)
      # not using the default key
      key = Digest::SHA256.digest(key) if key != StringEncrypter.default_key

      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      cipher.encrypt
      iv = cipher.random_iv
      cipher.key = key

      encrypted_text = cipher.update(string) + cipher.final
      return iv + encrypted_text
    end

    def self.decode(string, key: StringEncrypter.default_key)
      # not using the default key
      key = Digest::SHA256.digest(key) if key != StringEncrypter.default_key

      decipher = OpenSSL::Cipher::AES256.new(:CBC)
      decipher.decrypt
      decipher.key = key
      decipher.iv = string[0..15] # IV is always length 16
      encrypted_text = string[16..-1]

      decrypted_text = decipher.update(encrypted_text) + decipher.final
      return decrypted_text
    end
  end
end
