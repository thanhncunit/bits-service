require_relative './base'
require 'digest'
require 'base64'

module BitsService
  module Routes
    class Sign < Base
      get('/sign/packages/:guid') { |guid| sign('packages', packages_blobstore, guid, params['verb']) }
      get('/sign/buildpacks/:guid') { |guid| sign('buildpacks', buildpack_blobstore, guid, params['verb']) }
      get(%r{^/sign/buildpack_cache/entries/(.*/.*)}) { |path| sign('buildpack_cache/entries', buildpack_cache_blobstore, path, params['verb']) }
      get(%r{^/sign/droplets/(.*/.*)}) { |path| sign('droplets', droplet_blobstore, path, params['verb']) }

      private

      def sign(resource_type_name, blobstore, identifier, verb)
        if blobstore.local?
          sign_local("#{resource_type_name}/#{identifier}", verb)
        else
          sign_non_local(blobstore, identifier, verb)
        end
      end

      def sign_local(path, verb)
        expires = Time.now.utc.to_i + 3600
        signature = signer.sign("/signed/#{path}", expires)
        raise 'Configuration for public_endpoint should start with http://' unless public_endpoint.start_with?('http://')
        "#{public_endpoint}/signed/#{path}?md5=#{signature}&expires=#{expires}"
      end

      def sign_non_local(blobstore, identifier, verb)
        if verb == 'put'
          blobstore.public_upload_url(identifier)
        else
          blobstore.public_download_url(identifier)
        end
      end

      def signer
        @signer ||= NginxSigner.new(config[:secret])
      end
    end
  end
end
