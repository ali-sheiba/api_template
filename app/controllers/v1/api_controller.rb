# frozen_string_literal: true

class V1::ApiController < ApplicationController
  include JsonResponders
  include ExceptionHandler
  include MissingData
  include Consul::Controller

  before_action :authenticate_user!
  before_action :set_locale
  require_power_check

  self.responder = ApplicationResponder

  private

  # Set Power and inject it with current user
  current_power do
    Power.new(current_user)
  end

  # Set request locale
  def set_locale
    I18n.locale = params[:locale] || request.headers['locale'] || I18n.default_locale
  end
end
