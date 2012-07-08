# Lockdown for Reno Collective
require "json"
require "twitter"

class Tweet
  # Load external configuration information
  TWITTER = JSON.parse(File.open("config/twitter.json") { |file| file.read })

  # Configure twitter before we start the server
  Twitter.configure do |config|
    config.consumer_key = TWITTER["consumer_key"]
    config.consumer_secret = TWITTER["consumer_secret"]
  end

  def initialize(logger = nil)
    @logger = logger ||= Logger.new(STDOUT)
  end

  def tweet(msg)
    the_tweet = "#{msg} #{Time.now.to_s}"

    if ENV["RACK_ENV"] == "development"
      @logger.debug ">> Would have tweeted #{the_tweet}"
    else
      @twitter = Twitter::Client.new(
        :oauth_token => TWITTER["oauth_token"],
        :oauth_token_secret => TWITTER["oauth_token_secret"]
      )

      @twitter.update(the_tweet)
    end
  rescue Exception => e
    @logger.error "There was a problem tweeting the status ..."
    @logger.error e.inspect
  end
end