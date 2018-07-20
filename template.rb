# Inspired by :
# - https://github.com/excid3/jumpstart
# - https://github.com/astrocket/react-rails-template

require 'fileutils'
require 'shellwords'
require 'tmpdir'
require 'pry'

RAILS_REQUIREMENT = '~> 5.2.0'.freeze

def apply_template!
  assert_minimum_rails_version
  assert_postgresql
  add_template_repository_to_source_path

  template 'Gemfile.tt', force: true

  copy_file 'Capfile' if apply_capistrano?

  if apply_devise?
    # insert_into_file 'Gemfile', "gem 'devise-bootstrapped', github: 'king601/devise-bootstrapped', branch: 'bootstrap4'\n", after: /'consul'\n/
    insert_into_file 'Gemfile', "gem 'devise-jwt', '~> 0.5.6'\n", after: /'consul'\n/
    insert_into_file 'Gemfile', "gem 'devise-i18n'\n", after: /'consul'\n/
    insert_into_file 'Gemfile', "gem 'devise'\n", after: /'consul'\n/
  end

  copy_file 'gitignore',       '.gitignore',    force: true
  template  'ruby-version.tt', '.ruby-version', force: true
  # template  'ruby-gemset.tt',  '.ruby-gemset',  force: true

  # apply 'app/template.rb'
  # apply 'config/template.rb'
  # apply 'lib/template.rb'

  run  'gem install bundler'
  run  'bundle install'

  setup_gems
  setup_envs

  directory 'app/lib'

  run 'bundle binstubs bundler --force'
  run 'rails db:drop db:create db:migrate'

  git :init
  git add: '-A .'
  git commit: " -m 'Initial commit :star:'"

  finished!
end

def apply_capistrano?
  return @apply_capistrano if defined?(@apply_capistrano)
  @apply_capistrano = \
    ask_with_default('Use Capistrano for deployment?', :blue, 'no') \
    =~ /^y(es)?/i
end

def apply_devise?
  return @apply_devise if defined?(@apply_devise)
  @apply_devise = \
    ask_with_default('Use Devise for user authentication?', :blue, 'no') \
    =~ /^y(es)?/i
end

def apply_rspec?
  return @apply_rspec if defined?(@apply_rspec)
  @apply_rspec ||= \
    ask_with_default('Use Rspec for unit testing?', :blue, 'no') \
    =~ /^y(es)?/i
end

def ask_with_default(question, color, default)
  return default unless $stdin.tty?
  question = (question.split('?') << " [#{default}]?").join
  answer = ask(question, color)
  answer.to_s.strip.empty? ? default : answer
end

def setup_gems
  setup_bullet
  setup_erd
  if apply_devise?
    setup_devise
    setup_devise_jwt
  end
  setup_annotate
  setup_rspec if apply_rspec?
end

def setup_bullet
  inject_into_file 'config/environments/development.rb', before: /^end/ do
    <<-RUBY

  config.after_initialize do
    Bullet.enable = true
    Bullet.alert = true
    Bullet.bullet_logger = true
    Bullet.console = true
    Bullet.rails_logger = true
    Bullet.add_footer = true
  end
    RUBY
  end
end

def setup_erd
  generate 'erd:install'
  append_to_file '.gitignore', 'erd.pdf'
end

def setup_devise
  generate 'devise:install'
  gsub_file 'config/initializers/devise.rb', /#\s(config\.secret_key)\s=\s(.*)/, 'config.secret_key = Rails.application.credentials.secret_key_base'
  insert_into_file 'config/environments/development.rb', " \n config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }\n", before: /^end/

  generate 'devise', 'User'

  # Copy Controllers
  directory 'app/controllers/v1/auth'

  # Set BaseRoute
  gsub_file 'config/initializers/devise.rb', "  # config.parent_controller = 'DeviseController'", '  config.parent_controller = \'V1::Auth::DeviseController\''

  # Set Rouets
  gsub_file 'config/routes.rb', 'devise_for :users' do
    <<-RUBY
devise_for :users,
    controllers: {
      sessions: 'v1/auth/sessions',
      registrations: 'v1/auth/registrations',
      passwords: 'v1/auth/passwords'
    },
    path: 'v1/auth',
    defaults: { format: :json },
    path_names: { sign_in: 'login', sign_out: 'logout', registration: 'register' }
    RUBY
  end
end

def setup_devise_jwt
  inject_into_file 'config/initializers/devise.rb', before: /^  # ==> Controller configuration/ do
    <<-RUBY
    Devise.setup do |config|
      config.jwt do |jwt|
        jwt.secret = Rails.application.credentials.secret_key_base
        jwt.expiration_time = 1.day
      end
    end
    RUBY
  end

  # COPY jwt_warden_strategy
  copy_file 'config/initializers/jwt_warden_strategy.rb'

  # Generate WhitelistedJwt Model
  generate 'model', 'WhitelistedJwt'

  wl_migration = Dir['db/migrate/*'].find {|n| n.include?('create_whitelisted_jwts') }

  insert_into_file wl_migration, after: ":whitelisted_jwts do |t|\n" do
    <<-RUBY
      t.references :user, foreign_key: { on_delete: :cascade }, null: false
      t.string :jti, null: false
      t.string :aud
      t.datetime :exp, null: false
      t.index :jti, unique: true
    RUBY
  end

  inject_into_file 'app/models/user.rb', '  include Devise::JWT::RevocationStrategies::Whitelist', after: "User < ApplicationRecord\n"
  insert_into_file 'app/models/user.rb', ",\n         :jwt_authenticatable, jwt_revocation_strategy: self", after: ':validatable'
end

def setup_envs
  insert_into_file 'config/environments/development.rb', " \n config.action_mailer.delivery_method = :letter_opener\n", before: /^end/
end

def setup_annotate
  generate 'annotate:install'
end

def setup_rspec
  generate 'rspec:install'
  apply 'spec/template.rb'
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

def assert_postgresql
  return if IO.read('Gemfile') =~ /^\s*gem ['"]pg['"]/
  raise Rails::Generators::Error,
        'This template requires PostgreSQL, '\
        'but the pg gem isn’t present in your Gemfile.'
end

def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/ali-sheiba/api_template',
      tempdir
    ].map(&:shellescape).join(' ')
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def gemfile_requirement(name)
  @original_gemfile ||= IO.read('Gemfile')
  req = @original_gemfile[/gem\s+['"]#{name}['"]\s*(,[><~= \t\d\.\w'"]*)?.*$/, 1]
  req && req.tr("'", %(")).strip.sub(/^,\s*"/, ', "')
end

def run_bundle
  run 'bin/spring stop'
  p "Template setted."
  return
end

def finished!
  p '################################################################'
  p '###### run rails web server, run -> rails s ####################'
  p '################################################################'
end

apply_template!
