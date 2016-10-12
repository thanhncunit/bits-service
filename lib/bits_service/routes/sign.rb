require_relative './base'
require 'digest'
require 'base64'

module BitsService
  module Routes
    class Sign < Base
      get('/sign/packages/:guid') { |guid| sign('packages', packages_blobstore, guid) }
      get('/sign/buildpacks/:guid') { |guid| sign('buildpacks', buildpack_blobstore, guid) }
      get(%r{^/sign/droplets/(.*/.*)}) { |path| sign('droplets', droplet_blobstore, path) }

      private

      def sign(resource_type_name, blobstore, identifier)
        if blobstore.local?
          sign_local("#{resource_type_name}/#{identifier}")
        else
          sign_non_local(blobstore, identifier)
        end
      end

      def sign_local(path)
        expires = Time.now.utc.to_i + 3600
        signature = signer.sign("/signed/#{path}", expires)
        "http://#{public_endpoint}/signed/#{path}?md5=#{signature}&expires=#{expires}"
      end

      def sign_non_local(blobstore, identifier)
        blob = blobstore.blob(identifier)
        fail Errors::ApiError.new_from_details('NotFound', identifier) unless blob
        blob.public_download_url
      end

      def signer
        @signer ||= NginxSigner.new(config[:secret])
      end
    end
  end
end
