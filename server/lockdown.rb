# Lockdown for Reno Collective
require "json"
require "twitter"
require "logger"

# The "server"
class Lockdown
  # Load external configuration information
  TWITTER = JSON.parse(File.open("config/twitter.json") { |file| file.read })
  KEYS    = JSON.parse(File.open("config/keys.json") { |file| file.read })

  # Configure twitter before we start the server
  Twitter.configure do |config|
    config.consumer_key = TWITTER["consumer_key"]
    config.consumer_secret = TWITTER["consumer_secret"]
  end

  def call(env)
    @logger = Logger.new("log/lockdown.log")

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
    twitter = Twitter::Client.new(
      :oauth_token => TWITTER["oauth_token"],
      :oauth_token_secret => TWITTER["oauth_token_secret"]
    )

    twitter.update(msg)
  rescue Exception => e
    puts "There was a problem tweeting the status ..."
    puts e.inspect
  end
end