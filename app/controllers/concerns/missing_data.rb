# frozen_string_literal: true

module MissingData
  # Render and error if parameters are missing
  def missing_params!(*fields)
    missing_data(params, *fields, 1002)
  end

  # Render and error if headers are missing
  def missing_headers!(*fields)
    missing_data(request.headers, *fields, 1001)
  end

  # Shared Logic of missing params and headers
  def missing_data(data, *required_fields, error_code)
    missing = []

    required_fields.each { |f| missing << f unless data[f].present? }

    return render_smart_error(error: error_code, extra: missing) unless missing.blank?

    false
  end
end
