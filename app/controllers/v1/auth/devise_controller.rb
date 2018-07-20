# frozen_string_literal: true

class V1::Auth::DeviseController < ApplicationController
  self.responder = ApplicationResponder
  before_action :configure_permitted_parameters, if: :devise_controller?

  respond_to :json

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [])
  end

  def current_token
    request.env['warden-jwt_auth.token']
  end
end
