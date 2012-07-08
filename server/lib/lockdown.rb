require "json"
require "logger"
require_relative "lockdown/server"
require_relative "lockdown/tweet"

# Lockdown for Reno Collective
module Lockdown

  def self.development?
    ENV["RACK_ENV"] == "development"
  end

  # Load external configuration information
  KEYS   = JSON.parse(File.open("config/keys.json") { |file| file.read })
  LOGGER = development? ? Logger.new(STDOUT) : Logger.new("log/lockdown.log")

end

