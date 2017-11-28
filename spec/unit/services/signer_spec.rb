# frozen_string_literal: true

require 'spec_helper'

module BitsService
  module Routes
    describe NginxSigner do
      let(:signer) { NginxSigner.new(secret) }
      let(:secret) { 'geh3im' }

      it 'signs a url' do
        signature = signer.sign(
          '/signed/some/path',
          Time.parse('Tue, 19 Jan 2038 03:14:07 GMT')
)

        # http://nginx.org/en/docs/http/ngx_http_secure_link_module.html#secure_link_md5:
        # echo -n '2147483647/signed/some/path geh3im' | openssl md5 -binary | openssl base64 | tr +/ -_ | tr -d =
        expect(signature).to eq 'SkmibCs35Sy-75EmgmCibQ'
      end
    end
  end
end
