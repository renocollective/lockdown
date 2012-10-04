# twitter.rb

require "twitter"
require "celluloid"

module Lockdown
  TWITTER_CREDENTIALS = JSON.parse(File.open("config/twitter.json") { |file| file.read })

  class Tweet
    include Celluloid

    # Configure twitter before we start the server
    ::Twitter.configure do |config|
      config.consumer_key    = Lockdown::TWITTER_CREDENTIALS["consumer_key"]
      config.consumer_secret = Lockdown::TWITTER_CREDENTIALS["consumer_secret"]
    end

    def initialize
      @logger = Celluloid.logger = Lockdown::LOGGER
    end

    def tweet(msg)
      the_tweet = "#{msg} #{Time.now.to_s}"

      if Lockdown.development?
        @logger.info ">> Would have tweeted #{the_tweet}"
      else
        @twitter = ::Twitter::Client.new(
          oauth_token:        Lockdown::TWITTER_CREDENTIALS["oauth_token"],
          oauth_token_secret: Lockdown::TWITTER_CREDENTIALS["oauth_token_secret"]
        )

        @twitter.update(the_tweet)
      end
    rescue Exception => e
      @logger.error "There was a problem tweeting the status ..."
      @logger.error e.inspect
    end
  end
end