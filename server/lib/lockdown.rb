# lockdown.rb

require "json"
require "logger"

# Lockdown for Reno Collective
module Lockdown
  extend self

  def development?
    ENV["RACK_ENV"] == "development"
  end

  def root
    @root ||= File.expand_path(File.dirname(__FILE__))
  end

  def config_dir
    File.join(root, "..", "config")
  end

  def config_path(file)
    File.join(config_dir, file)
  end

  def log_dir
    File.join(root, "..", "log")
  end

  def log_path(file)
    File.join(log_dir, file)
  end

  def db_dir
    File.join(root, "..", "db")
  end

  def db_path(file)
    File.join(db_dir, file)
  end

  # Load external configuration information
  KEYS   = JSON.parse(File.open(Lockdown.config_path("keys.json")) { |file| file.read })
  LOGGER = development? ? Logger.new(STDOUT) : Logger.new(Lockdown.log_path("lockdown.log"))

end

require_relative "lockdown/server"
require_relative "lockdown/twitter"
require_relative "lockdown/freshbooks"