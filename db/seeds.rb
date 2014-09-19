# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

user = User.find_or_initialize_by(:email => ENV['SEED_EMAIL'] || "admin@example.com")
user.username = ENV['SEED_USERNAME'] || "admin"
user.password = ENV['SEED_PASSWORD'] || "password"
user.password_confirmation = ENV['SEED_PASSWORD'] || "password"
user.invitation_code = User::INVITATION_CODES.first
user.admin = true
user.save!

unless user.agents.where(:name => "VerveAPI").exists?
  Agent.build_for_type("Agents::WebhookAgent", user,
                       :name => "VerveAPI",
                       :options => { "secret" => "6995B2ED6ABE47DDB600E2302669A1C1",
                                     "expected_receive_period_in_days" => 1,
                                     "payload_path" => "payload" }).save!
  puts "NOTE: Agent created for VerveAPI to use for event creation"
end

unless user.agents.where(:name => "CreateAgentsAPI").exists?
  Agent.build_for_type("Agents::AgentCreatorAgent", user,
                       :name => "CreateAgentsAPI",
                       :options => { "secret" => "10294EF76BBE4212A24481FB0DFAF44A",
                                     "user" => "acaapi",
                                     "payload_path" => "agents"}).save!
  puts "NOTE: Agent Creator Agent API"
end

unless user.agents.where(:name => "DestroyAgentsAPI").exists?
  Agent.build_for_type("Agents::AgentDestroyerAgent", user,
                       :name => "DestroyAgentsAPI",
                       :options => {"user" => "adaapi",
                                    "secret" => "5AE2632B73BC4EABAC4D3C7B5AE17D7E",
                                    "payload_path" => "agents"}).save!
  puts "NOTE: Agent Destroyer Agent API"
end

puts "See the Huginn Wiki for more Agent examples!  https://github.com/cantino/huginn/wiki"
