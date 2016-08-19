require 'restful_model'

module Inbox
  class File < RestfulModel

    parameter :size
    parameter :filename
    parameter :content_id
    parameter :content_type
    parameter :is_embedded
    parameter :message_id

    # For uploading the file
    parameter :file

    def inflate(json)
      super
      content_type = json["content-type"] if json["content-type"]
    end

    def save!
      @_api.execute_request(method: :post, url: url, payload: {:file => @file}) do |response, request, result|
        json = Inbox.interpret_response(result, response, :expected_class => Object)
        json = json[0] if (json.class == Array)
        inflate(json)
      end
      self
    end

    def download
      download_url = self.url('download')
      @_api.execute_request(method: :get, url: download_url) do |response, request, result|
        Inbox.interpret_http_status(result)
        response
      end
    end

  end
end

