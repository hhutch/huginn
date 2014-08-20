class ChangeFieldtypeOfPayloadForEvents < ActiveRecord::Migration
  def up
    if postgresql?
      change_column :events, :payload, "JSON USING to_json(payload)"
    end
    # change_table :events do |t|
    #   t.change :payload, "JSON USING to_json(payload)"
    # end
  end
  
  def down
    if postgresql?
      change_column :events, :payload, :text
    end
    # change_table :events do |t|
    #   t.change :payload, :text
    # end
  end

  def postgresql?
    ActiveRecord::Base.connection.adapter_name =~ /postgres/i
  end
end
