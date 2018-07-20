# frozen_string_literal: true

class ApplicationController < ActionController::API
  self.responder = ApplicationResponder

  before_action :authenticate_user!
end
