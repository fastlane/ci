require "openssl"
require_relative "logging_module"

module FastlaneCI
  # makes encrypting string as easy as ijFkpReUM6kLfvry0A78cQ==
  class StringEncrypter
    include FastlaneCI::Logging

    class << self
      attr_accessor :_key
    end

    self._key = Digest::SHA256.digest(ENV["FASTLANE_CI_ENCRYPTION_KEY"])

    def self.encode(string, key: StringEncrypter._key)
      # not using the default key
      key = Digest::SHA256.digest(key) if key != StringEncrypter._key

      cipher = OpenSSL::Cipher::AES256.new(:CBC)
      cipher.encrypt
      iv = cipher.random_iv
      cipher.key = key

      encrypted_text = cipher.update(string) + cipher.final
      return iv + encrypted_text
    end

    def self.decode(string, key: StringEncrypter._key)
      # not using the default key
      key = Digest::SHA256.digest(key) if key != StringEncrypter._key

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
