module BitsService
  module Blobstore
    class NginxSecureLinkSigner
      def initialize(internal_endpoint:, internal_path_prefix: nil,
        public_endpoint:, public_path_prefix: nil, basic_auth_user:, basic_auth_password:, http_client:)

        @internal_uri         = URI(internal_endpoint)
        @internal_path_prefix = internal_path_prefix
        @public_uri           = URI(public_endpoint)
        @public_path_prefix   = public_path_prefix

        @client = http_client

        @headers = {}
        @headers['Authorization'] = 'Basic ' + Base64.strict_encode64("#{basic_auth_user}:#{basic_auth_password}").strip
      end

      def sign_internal_url(expires:, path:)
        request_uri  = uri(expires: expires, path_to_be_signed: File.join([@internal_path_prefix, path].compact), sign_prefix: '/sign')
        response_uri = make_request(uri: request_uri)

        signed_uri        = @internal_uri.clone
        signed_uri.scheme = 'https'
        signed_uri.path   = response_uri.path
        signed_uri.query  = response_uri.query
        signed_uri.to_s
      end

      def sign_public_url(expires:, path:)
        request_uri  = uri(expires: expires, path_to_be_signed: File.join([@public_path_prefix, path].compact), sign_prefix: '/sign')
        response_uri = make_request(uri: request_uri)

        signed_uri        = @public_uri.clone
        signed_uri.scheme = 'http'
        signed_uri.path   = response_uri.path
        signed_uri.query  = response_uri.query
        signed_uri.to_s
      end

      def sign_public_upload_url(expires:, path:)
        request_uri  = uri(expires: expires, path_to_be_signed: File.join([@public_path_prefix, path].compact), sign_prefix: '/sign_for_put')
        response_uri = make_request(uri: request_uri)

        signed_uri        = @public_uri.clone
        signed_uri.scheme = 'http'
        signed_uri.path   = response_uri.path
        signed_uri.query  = response_uri.query
        signed_uri.to_s
      end

      private

      def make_request(uri:)
        response = @client.get(uri, header: @headers)

        raise SigningRequestError.new("Could not get a signed url, #{response.status}/#{response.content}") unless response.status == 200

        URI(response.content)
      end

      def uri(expires:, path_to_be_signed:, sign_prefix:)
        uri       = @internal_uri.clone
        uri.path  = sign_prefix
        uri.query = {
          expires: expires,
          path:    File.join(['/', path_to_be_signed])
        }.to_query

        uri.to_s
      end
    end
  end
end
