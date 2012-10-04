#! /usr/bin/env ruby

# cache_keys.rb


require_relative "../lib/lockdown.rb"

if $0 == __FILE__

  ACCOUNT  = ENV["FRESHBOOKS_ACCOUNT"]
  TOKEN    = ENV["FRESHBOOKS_TOKEN"]
  LOGGER   = Lockdown::LOGGER

  begin
    LOGGER.info "Caching keys"

    fb   = Lockdown::Freshbooks.new(ACCOUNT, TOKEN)
    json = fb.active_keys_json

    LOGGER.info ">> #{fb.active_keys.length} keys retrieved"

    unless json.strip.empty?
      File.open(Lockdown.db_path("keys.json"), "w") do |keys|
        keys.puts json
      end
    end

    LOGGER.info "Keys cached"
  rescue Exception => e
    LOGGER.error "An error occurred. "
  end
end

