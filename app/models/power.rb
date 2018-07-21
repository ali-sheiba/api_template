# frozen_string_literal: true

class Power
  include Consul::Power

  attr_reader :current_user

  def initialize(current_user)
    @current_user = current_user
  end

  # Generate powers for all tables and by default prevent them all from access
  ActiveRecord::Base.connection.tables.map(&:to_sym) - %i[schema_migrations ar_internal_metadata].each do |model|
    power model do
      false
    end
  end
end
