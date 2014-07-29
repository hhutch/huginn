require 'date'
require 'cgi'

module Agents
  class FitbitAgent < Agent
    cannot_receive_events!

    description <<-MD
      TESTING 1 2 3 4 

      Fitbit credentials must be supplied as either credentials called fitbit_consumer_key, fitbit_consumer_secret, fitbit_oauth_token, and fitbit_oauth_token_secret, or as options to this Agent called consumer_key, consumer_secret, oauth_token, and oauth_token_secret.

      To get oAuth credentials for Fitbit ...
    MD

    event_description <<-MD
      Events look like this:
         {}
    MD

    default_schedule "7am"

    def working?
      event_created_within?((interpolated['expected_update_period_in_days'].presence || 2).to_i) && !recent_error_logs?
    end

    def key_setup?
      interpolated['consumer_key'].present? && interpolated['consumer_key'] != "your-key"
    end

    def default_options
      {
        'consumer_key' => 'your-key',
        'consumer_secret' => 'your-secret'
      }
    end

    def which_day
      (interpolated["which_day"].presence || 1).to_i
    end

    # def location
    #   interpolated["location"].presence || interpolated["zipcode"]
    # end

    def validate_options
      errors.add(:base, "Consumer Key is required") unless consumer_key.present
      errors.add(:base, "Consumer Secret is required") unless consumer_secret.present?
      
      # errors.add(:base, "consumer_key is required") unless key_setup?
      # errors.add(:base, "which_day selection is required") unless which_day.present?
    end

    def fitbit
      @client ||= Fitgem::Client.new(:consumer_key => ENV["FITBIT_KEY"],
                                     :consumer_secret => ENV["FITBIT_SECRET"],
                                     :token => auth.oauth_token,
                                     :secret => auth.oauth_secret,
                                     :user_id => auth.uid)

      # Wunderground.new(interpolated['consumer_key']).forecast_for(location)['forecast']['simpleforecast']['forecastday'] if key_setup?
    end


    def model(service,which_day)
      if service == "wunderground"
        wunderground[which_day]
      end
    end

    def check
      if key_setup?
        create_event :payload => model(service, which_day).merge('location' => location)
      end
    end

  end
end
