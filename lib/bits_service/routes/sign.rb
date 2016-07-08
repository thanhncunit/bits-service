require_relative './base'
require 'digest'
require 'base64'

module BitsService
  module Routes
    class Sign < Base
      get %r{/sign/(.+)} do |path|
        expires = Time.now.utc.to_i + 3600
        signature = signer.sign("/signed/#{path}", expires)
        "http://#{public_endpoint}/signed/#{path}?md5=#{signature}&expires=#{expires}"
      end

      private

      def signer
        @signer ||= NginxSigner.new(config[:secret])
      end
    end
  end
end
