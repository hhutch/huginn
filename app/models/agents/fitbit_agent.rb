require 'date'
require 'cgi'

module Agents
  class FitbitAgent < Agent
    # cannot_receive_events!

    description <<-MD
      Fitbit credentials must be supplied as either credentials called `fitbit_consumer_key`, `fitbit_consumer_secret`, `fitbit_oauth_token`, and `fitbit_oauth_token_secret`, or as options to this Agent called `consumer_key`, `consumer_secret`, `oauth_token`, and `oauth_token_secret`.

      To get oAuth credentials for Fitbit ... [follow these instructions](https://dev.fitbit.com/apps/oauthtutorialpage)
    MD

    event_description <<-MD
      Events look like this:
         {}
    MD

    default_schedule "7am"

    def working?
      event_created_within?((interpolated['expected_update_period_in_days'].presence || 2).to_i) && !recent_error_logs?
    end

    def default_options
      {
        'consumer_key' => 'your-key',
        'consumer_secret' => 'your-secret',
        'oauth_token' => 'your-oauth-token',
        'oauth_secret' => 'your-oauth-secret',
        'uid' => 'fitbit user id'
      }
    end

    def validate_options
      errors.add(:base, "Consumer Key is required") unless options['consumer_key'].present?
      errors.add(:base, "Consumer Secret is required") unless options['consumer_secret'].present?
    end

    def fitbit
      @client ||= Fitgem::Client.new(:consumer_key => options['consumer_key'],
                                     :consumer_secret => options['consumer_secret'],
                                     :token => options['oauth_token'],
                                     :secret => options['oauth_secret'],
                                     :user_id => options['uid'])
      @client.activities_on_date('today')
    end


    def model()
      fitbit
    end

    def check
      create_event :payload => model()
      # create_event :payload => {"foo" => "bar"}
    end

  end
end
