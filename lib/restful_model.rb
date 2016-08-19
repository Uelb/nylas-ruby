require 'time_attr_accessor'
require 'parameters'

module Inbox
  class RestfulModel
    extend Inbox::TimeAttrAccessor
    include Inbox::Parameters

    parameter :id
    parameter :account_id
    parameter :cursor  # Only used by the delta sync API
    time_attr_accessor :created_at
    attr_reader :raw_json

    def self.collection_name
      "#{self.to_s.downcase}s".split('::').last
    end

    def initialize(api, account_id = nil)
      raise StandardError.new unless api.class <= Inbox::API
      @account_id = account_id
      @_api = api
    end

    def ==(comparison_object)
      comparison_object.equal?(self) || (comparison_object.instance_of?(self.class) && comparison_object.id == id)
    end

    def inflate(json)
      @raw_json = json
      parameters.each do |property_name|
        send("#{property_name}=", json[property_name]) if json.has_key?(property_name)
      end
    end

    def save!(params={})
      if id
        update('PUT', '', as_json(), params)
      else
        update('POST', '', as_json(), params)
      end
    end

    def url(action = "")
      action = "/#{action}" unless action.empty?
      @_api.url_for_path("/#{self.class.collection_name}/#{id}#{action}")
    end

    def as_json(options = {})
      hash = {}
      parameters.each do |getter|
        unless options[:except] && options[:except].include?(getter)
          value = send(getter)
          unless value.is_a?(RestfulModelCollection)
            value = value.as_json(options) if value.respond_to?(:as_json)
            hash[getter] = value
          end
        end
      end
      hash
    end

    def update(http_method, action, data = {}, params = {})
      http_method = http_method.downcase

      url = self.url(action)
      @_api.execute_request(method: http_method, url: url, payload: data, headers: {:content_type => :json, :params => params}) do |response, request, result|
        unless http_method == 'delete'
          json = Inbox.interpret_response(result, response, :expected_class => Object)
          inflate(json)
        end
      end
      self
    end

    def destroy(params = {})
      @_api.execute_request(method: 'delete', url: self.url, headers: {:params => params}) do |response, request|
        Inbox.interpret_http_status(response)
      end
    end

  end
end
