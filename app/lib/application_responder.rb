# frozen_string_literal: true

class ApplicationResponder < ActionController::Responder
  protected

  def json_resource_errors
    {
      message: resource.errors.full_messages.to_sentence,
      errors:  resource.errors
    }
  end
end
