# frozen_string_literal: true

require 'dotenv/load'
require_relative 'multipass'

MULTIPASS_KEY = ENV['MULTIPASS_KEY']
ONLINE_STORE = ENV['ONLINE_STORE']

customer_data = {
  email: 'example@grovej.com',
  return_to: "https://#{ONLINE_STORE}/checkout"
}

token = Multipass.generate_token(MULTIPASS_KEY, customer_data)

puts "https://#{ONLINE_STORE}/account/login/multipass/#{token}" if token
