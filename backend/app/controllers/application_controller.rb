class ApplicationController < ActionController::API
  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_record_invalid
  rescue_from ActionController::ParameterMissing, with: :render_bad_request
  rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_malformed_json

  def route_not_found
    render_error("Not found", :not_found)
  end

  private

  def render_error(message, status)
    render json: { error: message }, status: status
  end

  def render_not_found(exception)
    render_error("#{exception.model || 'Record'} not found", :not_found)
  end

  def render_record_invalid(exception)
    render_error(exception.record.errors.full_messages.to_sentence, :unprocessable_content)
  end

  def render_bad_request(exception)
    render_error("Missing parameter: #{exception.param}", :bad_request)
  end

  def render_malformed_json
    render_error("Malformed JSON request body", :bad_request)
  end

  def render_internal_error(exception)
    Rails.logger.error(exception.full_message)
    render_error("Internal server error", :internal_server_error)
  end
end
