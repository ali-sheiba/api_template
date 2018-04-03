# Inspired by https://github.com/excid3/jumpstart

def source_paths
  [File.expand_path(File.dirname(__FILE__))]
end

def add_gems
  gem 'active_model_serializers', '~> 0.10.0'
  gem 'bcrypt', '~> 3.1.7'
  gem 'consul'
  gem 'email_validator'
  gem 'enumerize'
  gem 'redis', '~> 4.0'
  gem 'jwt'
  gem 'kaminari'
  gem 'rack-attack'
  gem 'rack-cors', require: 'rack/cors'
  gem 'ransack'
  gem 'smart_error'
  gem 'paperclip', '~> 6.0.0'

  gem_group :development, :test do
    gem 'pry-rails'
    gem 'faker'
    gem 'factory_bot_rails'
    gem 'rspec-rails', '~> 3.7'
    gem 'shoulda'
    gem 'annotate', github: 'ctran/annotate_models', branch: :develop
  end
end

# Main setup
add_gems

after_bundle do

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit :star:' }
end