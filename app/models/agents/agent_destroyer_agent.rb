module Agents
  class AgentDestroyerAgent < Agent
    cannot_be_scheduled!
    cannot_receive_events!

    description do
      <<-MD
      Deregisters Agents of <type> based on specifically formatted incoming events

      Make a POST to:
      ```
         https://#{ENV['DOMAIN']}/users/#{user.id}/web_requests/#{id || '<id>'}/:secret
      ```

      Set `expected_receive_period_in_days` to the maximum amount of time that you'd expect to pass between Events being received by this Agent.
    MD
    end

    def working?
      !recent_error_logs?
    end

    def default_options
      {"user" => "hilbilly",
       "secret" => "garfunkle",
       "payload_path" => "agents"}
    end

    def receive_web_request(params, method, format)
      secret = params.delete('secret')
      return ["Please use POST requests only", 401] unless method == "post"
      return ["Not Authorized", 401] unless secret == interpolated['secret']

      agent_list = Utils.value_at(params, interpolated['payload_path'])
      
      agent_list.each { |req_a|
        ex_a = Agent.where({:user_id => user,
                            :name => req_a["name"],
                            :type => "Agents::#{req_a["type"]}"}).first
        if !ex_a.nil?
          ex_a.delete
        end
      }
      
      ["success", 201]
    end

    def validate_options
      unless options['secret'].present?
        errors.add(:base, "Must specify a secret for 'Authenticating' requests")
      end
    end

    def payload_for(params)
      Utils.value_at(params, interpolated['payload_path']) || {}
    end
  end
end
