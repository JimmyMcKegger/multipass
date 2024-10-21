# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'time'
require 'json'

CIPHER_ALGORITHM = 'aes-128-cbc'
HASH_ALGORITHM = 'sha256'

# Implementation of Shopify's multipass token generator
# see https://shopify.dev/docs/api/multipass
module Multipass
  class << self
    def generate_token(multipass_secret, customer_data_hash)
      validate_input(customer_data_hash)
      keys = generate_keys(multipass_secret)
      ciphertext = create_ciphertext(customer_data_hash, keys[:encryption_key])
      token = create_token(ciphertext, keys[:signature_key])
      Base64.urlsafe_encode64(token)
    rescue StandardError => e
      puts "Error generating token: #{e.message}"
      nil
    end

    private

    def validate_input(customer_data_hash)
      raise ArgumentError, 'customer_data_hash must be a Hash' unless customer_data_hash.is_a?(Hash)
      raise ArgumentError, 'Email is required' unless customer_data_hash[:email]
    end

    def generate_keys(multipass_secret)
      key_material = OpenSSL::Digest.new(HASH_ALGORITHM).digest(multipass_secret)
      {
        encryption_key: key_material[0, 16],
        signature_key: key_material[16, 16]
      }
    end

    def create_ciphertext(customer_data_hash, encryption_key)
      customer_data = customer_data_hash.merge('created_at' => Time.now.utc.iso8601)
      encrypt(customer_data.to_json, encryption_key)
    end

    def create_token(ciphertext, signature_key)
      ciphertext + sign(ciphertext, signature_key)
    end

    def encrypt(plaintext, encryption_key)
      cipher = OpenSSL::Cipher.new(CIPHER_ALGORITHM)
      cipher.encrypt
      cipher.key = encryption_key
      cipher.iv = iv = cipher.random_iv

      iv + cipher.update(plaintext) + cipher.final
    end

    def sign(data, signature_key)
      OpenSSL::HMAC.digest(HASH_ALGORITHM, signature_key, data)
    end
  end
end
