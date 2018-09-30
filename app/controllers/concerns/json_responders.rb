# frozen_string_literal: true

module JsonResponders
  # Render a message
  def render_success(message: I18n.t(:data_found), data: {})
    render json: { message: message, **data }, status: :ok
  end

  # Render Created
  def render_created(data:, message: I18n.t(:created_successfully))
    render json: { message: message, **data }, status: :created
  end

  ## Error Responders
  def render_bad_request(error: 1000, **options)
    render_smart_error(error: error, **options)
  end

  def render_unauthorized(error: 1101, **options)
    render_smart_error(error: error, status: :unauthorized, **options)
  end

  def render_forbidden(error: 1102, **options)
    render_smart_error(error: error, status: :forbidden, **options)
  end

  def render_unprocessable_entity(error: 1103, **options)
    render_smart_error(error: error, status: :unprocessable_entity, **options)
  end

  def render_not_found(error: 1105, **options)
    render_smart_error(error: error, status: :not_found, **options)
  end

  def render_smart_error(error:, **options)
    response = SmartError.handle(error, options).to_h

    render_error(
      error_code: response[:error_code],
      message:    response[:message],
      status:     (options[:status] || :bad_request),
      data:       response[:details].empty? ? options[:data] : response[:details]
    )
  end

  def render_error(params = {})
    error_code = params[:error_code] || 1010
    message    = params[:message]    || I18n.t(:bad_request)
    status     = params[:status]     || :bad_request
    data       = params[:data]       || {}

    # will print the error in the console with colour
    Rails.logger.debug("  \e[41;1mError Response:\e[0m\e[41m #{error_code} | #{message}\e[0m")

    render json: {
      error:      message,
      error_code: error_code,
      data:       data
    }, status: status
  end
end
