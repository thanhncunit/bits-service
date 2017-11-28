# frozen_string_literal: true

require 'digest'
require 'base64'

module BitsService
  class NginxSigner
    def initialize(secret)
      raise 'secret must be at least 3 characters long' if secret.to_s.length < 3
      @secret = secret
    end

    def sign(path, expires_at)
      # This pattern must match the 'secure_link_md5' pattern defined in
      # bits-service-release/jobs/bits-service/templates/nginx.conf.erb
      to_sign = "#{expires_at.to_i}#{path} #{@secret}"
      Base64.strict_encode64(Digest::MD5.digest(to_sign)).tap do |result|
        result.tr!('+/', '-_')
        result.tr!('=', '')
      end
    end
  end
end
