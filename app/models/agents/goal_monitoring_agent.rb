module Agents
  class GoalMonitoringAgent < Agent
    cannot_be_scheduled!

    VALID_COMPARISON_TYPES = %w[regex !regex field<value field<=value field==value field!=value field>=value field>value]

    description <<-MD
      Verve Goal Monitoring Agent
    MD

    event_description <<-MD
      Events look like this:

          { "verve_goal_id" : 33,
            "verve_user_id" : 14,
            "goal_match_value" : "some-value" }
    MD

    def validate_options
      unless options['expected_receive_period_in_days'].present? && options['rules'].present? &&
             options['rules'].all? { |rule| rule['type'].present? && VALID_COMPARISON_TYPES.include?(rule['type']) && rule['value'].present? && rule['path'].present? }
        errors.add(:base, "expected_receive_period_in_days, message, and rules, with a type, value, and path for every rule, are required")
      end
    end

    def default_options
      {
        'expected_receive_period_in_days' => "2",
        'verve_goal_id' => 33,
        'verve_user_id' => 14,
        'rules' => [{
                      'type' => "regex",
                      'value' => "foo\\d+bar",
                      'path' => "topkey.subkey..goal",
                    }],
        'goal_payload' => { "goal_match_value" => "{{topkey.subkey.goal}}" }
      }
    end

    def working?
      last_receive_at && last_receive_at > interpolated['expected_receive_period_in_days'].to_i.days.ago && !recent_error_logs?
    end

    def receive(incoming_events)
      incoming_events.each do |event|

        opts = interpolated(event)

        match = opts['rules'].all? do |rule|
          value_at_path = Utils.value_at(event['payload'], rule['path'])
          rule_values = rule['value']
          rule_values = [rule_values] unless rule_values.is_a?(Array)

          match_found = rule_values.any? do |rule_value|
            case rule['type']
            when "regex"
              value_at_path.to_s =~ Regexp.new(rule_value, Regexp::IGNORECASE)
            when "!regex"
              value_at_path.to_s !~ Regexp.new(rule_value, Regexp::IGNORECASE)
            when "field>value"
              value_at_path.to_f > rule_value.to_f
            when "field>=value"
              value_at_path.to_f >= rule_value.to_f
            when "field<value"
              value_at_path.to_f < rule_value.to_f
            when "field<=value"
              value_at_path.to_f <= rule_value.to_f
            when "field==value"
              value_at_path.to_s == rule_value.to_s
            when "field!=value"
              value_at_path.to_s != rule_value.to_s
            else
              raise "Invalid type of #{rule['type']} in TriggerAgent##{id}"
            end
          end
        end

        if match
          payload = { "verve_goal_id" => opts["verve_goal_id"],
                      "verve_user_id" => opts["verve_user_id"] }
  
          create_event :payload => opts['goal_payload'].merge!(payload)
          
        end
      end
    end

  end
end
