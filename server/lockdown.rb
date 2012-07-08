# Lockdown for Reno Collective
require "json"
require "logger"
require "./tweet"

# The "server"
class Lockdown
  # Load external configuration information
  KEYS   = JSON.parse(File.open("config/keys.json") { |file| file.read })

  def call(env)
    @logger = Logger.new("log/lockdown.log")
    @tweet  = Tweet.new

    content_type = {"Content-Type" => "text/html"}
    request      = Rack::Request.new(env)

    if scanned = request["id"]
      @logger.info ">> Scanned #{scanned} at #{Time.now.to_s}"

      if account = KEYS[scanned]
        msg = "Unlocking the door for #{account}"
        @logger.info msg
        notify msg
        [ 200, content_type, [msg] ]
      else
        msg = "Can't open the door for unknown RFID."
        @logger.error msg
        notify msg
        [ 503, content_type, [msg] ]
      end
    else
      @logger.error "Unhandled request."
      # return an error for everything else
      [500, content_type, "Missing id parameter."]
    end
  end

  def notify(msg)
    # use celluloid to do this async
    @tweet.tweet!(msg)
  end
end