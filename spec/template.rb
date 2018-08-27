copy_file '.rspec', force: true

directory 'spec/support'

inject_into_file 'spec/rails_helper.rb', after: /\'spec_helper\'\n/ do
  <<-RUBY
require 'shoulda/matchers'
require 'support/factory_bot'
require 'support/database_cleaner'
require 'support/request_helpers'
# require 'support/shoulda'

  RUBY
end

inject_into_file 'spec/rails_helper.rb', before: /^end/ do
  <<-RUBY

  config.include Requests::JsonHelpers, type: :request
  # config.include Requests::AuthHelpers, type: :request

  Shoulda::Matchers.configure do |matchers|
    matchers.integrate do |with|
      with.test_framework :rspec
      with.library :rails
    end
  end
  RUBY
end
