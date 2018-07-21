# frozen_string_literal: true

class ApiControllerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)
  class_option :skip_power, type: :boolean, desc: "Don't add powers to controller and power.rb"

  desc 'Generate Api Controller'
  def create_presenter_file
    template 'controller.rb', File.join('app/controllers', class_path, "#{file_name}_controller.rb")
  end

  def add_powers
    return unless power?
    insert_into_file 'app/models/power.rb', before: /^end/ do
      <<-RUBY

  ######################## #{class_name}Controller #######################

  power :#{file_name.pluralize}_index do
    #{model_name}
  end

  power :#{file_name}_show do
    #{model_name}
  end

  power :creatable_#{file_name} do
    #{model_name}
  end

  power :updatable_#{file_name} do
    #{model_name}
  end

  power :destroyable_#{file_name} do
    #{model_name}
  end
      RUBY
    end
  end

  private

  def power?
    return false if options[:skip_power]
    File.file?('app/models/power.rb')
  end

  def model_name
    class_name.singularize.split('::').last
  end

  def controller_powers
    return unless power?
    "  power :#{file_name.pluralize}, map: {
    [:index]   => :#{file_name.pluralize}_index,
    [:show]    => :#{file_name}_show,
    [:create]  => :creatable_#{file_name},
    [:update]  => :updatable_#{file_name},
    [:destroy] => :destroyable_#{file_name}
  }, as: :#{file_name.pluralize}_scope\n"
  end
end
