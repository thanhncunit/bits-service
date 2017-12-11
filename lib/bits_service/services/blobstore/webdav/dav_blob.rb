# frozen_string_literal: true

require 'bits_service/services/blobstore/webdav/nginx_secure_link_signer'

module BitsService
  module Blobstore
    class DavBlob
      attr_reader :key

      def initialize(httpmessage:, key:, signer:)
        @httpmessage = httpmessage
        @key         = key
        @signer      = signer
      end

      def internal_download_url
        expires = Time.now.utc.to_i + 3600
        @signer.sign_internal_url(path: @key, expires: expires)
      end

      def public_download_url
        expires = Time.now.utc.to_i + 3600
        @signer.sign_public_url(path: @key, expires: expires)
      end

      def public_upload_url
        expires = Time.now.utc.to_i + 3600
        @signer.sign_public_upload_url(path: @key, expires: expires)
      end

      def attributes(*keys)
        @attributes ||= {
          etag:           @httpmessage.headers['ETag'],
          last_modified:  @httpmessage.headers['Last-Modified'],
          content_length: @httpmessage.headers['Content-Length'],
          created_at:     nil
        }

        return @attributes if keys.empty?
        @attributes.select { |key, _| keys.include? key }
      end
    end
  end
end
