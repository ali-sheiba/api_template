# frozen_string_literal: true

class V1::ApiController < ApplicationController
  include JsonResponders
  include ExceptionHandler

  self.responder = ApplicationResponder

  before_action :authenticate_user!
end
