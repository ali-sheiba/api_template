# frozen_string_literal: true

class ApplicationResponder < ActionController::Responder
  protected

  def json_resource_errors
    {
      error:      resource.errors.full_messages.to_sentence,
      error_code: 1010,
      data:       resource.errors.messages.transform_values(&:to_sentence)
    }
  end
end
