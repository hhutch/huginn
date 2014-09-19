module Agents
  class AgentCreatorAgent < Agent
    cannot_be_scheduled!
    cannot_receive_events!

    description do
      <<-MD
      Registers Agents of <type> based on specifically formatted incoming events

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
      { # "agent_type" => "sumfin",
        "user" => "hilbilly",
        # "name" => "nord",
        # "schedule" => nil,
        # "keep_events" => nil,
        # "sources" => [],
        # "options" => {}
        "secret" => "garfunkle",
        "payload_path" => "agents"
      }
    end

    def receive_web_request(params, method, format)
      secret = params.delete('secret')
      return ["Please use POST requests only", 401] unless method == "post"
      return ["Not Authorized", 401] unless secret == interpolated['secret']

      # puts "our params: #{params}"
      agent_list = Utils.value_at(params, interpolated['payload_path'])
      built_agent = nil
      
      agent_list.each { |req_a|
        ex_a = Agent.where({:user_id => user, :type => "Agents::#{req_a["type"]}"}).first
        if ex_a.nil?
          # create new agent
          agent_args = {:name => req_a["name"], :options => req_a["options"]}
          # source will be sent as a valid name, must fetch the ID
          unless req_a["source"].nil?
            source = Agent.where({:user_id => user, :name => req_a["source"]}).first
            agent_args[:source_ids] = [source.id]
          end
          unless req_a["schedule"].nil?
            agent_args[:schedule] = req_a["schedule"]
          end
          Agent.build_for_type("Agents::#{req_a["type"]}", user, agent_args).save!
          built_agent = Agent.where({:user_id => user, :type => "Agents::#{req_a["type"]}"}).first
        else
          # update existing agent
          # ex_a["sources"] = req_a["sources"]
          ex_a["options"].each { |aopt|
            ex_a["options"][aopt.first] = req_a["options"][aopt.first]
          }
          ex_a.save!
          built_agent = ex_a
        end
      }
      
      [{:agent_id => built_agent.id}.to_json, 201]
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
