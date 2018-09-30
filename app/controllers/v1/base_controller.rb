# frozen_string_literal: true

class V1::BaseController < V1::ApiController
  before_action :find_resource, only: %i[show update destroy]
  ## ------------------------------------------------------------ ##

  # GET : /v2/{resource}
  def index
    data = {
      index_key => collection.as_api_response(index_template, template_injector),
      pagination: pagination(collection)
    }

    yield data if block_given?
    render_success(data: data, message: index_message)
  end

  ## ------------------------------------------------------------ ##

  # GET : /v2/{resource}/:id
  def show
    return render_not_found if resource.nil?

    data = { show_key => resource.as_api_response(show_template, template_injector) }
    yield data if block_given?
    render_success(data: data)
  end

  ## ------------------------------------------------------------ ##

  # POST : /v2/{resource}/:id
  def create
    find_resource(scope.new(params_processed))
    if resource.save
      data = { show_key => resource.as_api_response(show_template, template_injector) }
      yield data, resource if block_given?
      render_created(data: data, message: created_message)
    else
      render_unprocessable_entity(error: resource)
    end
  end

  ## ------------------------------------------------------------ ##

  # PUT : /v2/{resource}/:id
  def update
    if resource.update(params_processed)
      data = { show_key => resource.as_api_response(show_template, template_injector) }
      # yield data if block_given?
      render_success(data: data, message: updated_message)
    else
      render_unprocessable_entity(error: resource)
    end
  end

  ## ------------------------------------------------------------ ##

  # DELETE : /v2/{resource}/:id
  def destroy
    if resource.destroy
      render_success(message: destroyed_message, data: { id: resource.id })
    else
      render_unprocessable_entity(error: resource)
    end
  end

  ## ------------------------------------------------------------ ##

  private

  def scope
    scope_name = "#{resource_name.pluralize}_scope"
    @scope ||= send(scope_name)
  rescue NoMethodError
    resource_class
  end

  def find_resource(resource = nil)
    resource ||= scope.find(id_parameter)
    instance_variable_set("@#{resource_name}", resource)
  rescue ActiveRecord::RecordNotFound
    render_not_found
  end

  def resource
    instance_variable_get("@#{resource_name}")
  end

  def resource_class
    @resource_class ||= resource_name.classify.constantize
  end

  def resource_name
    @resource_name ||= controller_name.singularize
  end

  def resource_params
    @resource_params ||= send("#{resource_name}_params")
  end

  def params_processed
    resource_params
  end

  def collection
    @collection ||= build_collection
  end

  def build_collection(object = nil)
    result = (object || scope)
    result = result.ransack(search_params).result           if search_params.present?
    result = result.page(params[:page]).per(params[:limit]) if params[:limit] != '-1'
    result = result.order(collection_order)                 if collection_order.present?
    result
  end

  def search_params
    params[:q]
  end

  def collection_order
    {
      created_at: :desc
    }
  end

  def id_parameter
    params[:id]
  end

  def pagination(object)
    {
      current_page:  object.try(:current_page) || 1,
      next_page:     object.try(:next_page),
      previous_page: object.try(:prev_page),
      total_pages:   object.try(:total_pages) || 1,
      per_page:      object.try(:limit_value),
      total_entries: object.try(:total_count) || object.count
    }
  end

  def template_injector
    {}
  end

  def index_key
    resource_name.to_s.pluralize.to_sym
  end

  def show_key
    resource_name.to_s.singularize.to_sym
  end

  # the default show template
  def show_template
    :show
  end

  # the default index template
  def index_template
    :index
  end

  # Messages
  def index_message
    I18n.t(collection.to_a.size.zero? ? 'no_data_found' : 'data_found')
  end

  def created_message
    I18n.t(:x_created_successfully, name: resource_class.model_name.human)
  end

  def updated_message
    I18n.t(:x_update_successfully, name: resource_class.model_name.human)
  end

  def destroyed_message
    I18n.t(:x_deleted_successfully, name: resource_class.model_name.human)
  end
end
