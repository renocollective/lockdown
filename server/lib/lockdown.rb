require "json"
require "logger"
require_relative "lockdown/server"
require_relative "lockdown/tweet"

# Lockdown for Reno Collective
module Lockdown
  # Load external configuration information
  KEYS = JSON.parse(File.open("config/keys.json") { |file| file.read })
end

