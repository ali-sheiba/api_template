# frozen_string_literal: true

class ApiControllerGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  desc 'Generate Api Controller'
  def create_presenter_file
    template 'controller.rb', File.join('app/controllers', class_path, "#{file_name}_controller.rb")
  end
end
