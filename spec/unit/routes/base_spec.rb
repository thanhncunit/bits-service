# frozen_string_literal: true

require 'spec_helper'

module BitsService
  describe Routes::Base do
    it 'returns a VCAP request ID if it was present in the request' do
      # We return X_VCAP_REQUEST_ID when getting HTTP_X_VCAP_REQUEST_ID
      # because of the CGI spec
      post '/some_endpoint', nil, { 'HTTP_X_VCAP_REQUEST_ID' => 'test-value' }
      expect(last_response.headers).to include('X_VCAP_REQUEST_ID' => 'test-value')
    end

    it 'returns no VCAP request ID if it was not present in the request' do
      get '/some_other_endpoint'
      expect(last_response.headers).to_not include('X_VCAP_REQUEST_ID')
    end
  end
end
