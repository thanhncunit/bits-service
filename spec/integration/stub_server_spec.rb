# frozen_string_literal: true

require 'spec_helper'
require 'stub_server'
require 'open-uri'

module BitsService
  describe 'Stub Server', type: :integration do
    let(:port) { rand((40000..50000)) } # choosing a random port between 40000 and 50000, because it's unlikely that these are already used.

    # For full verification, we would need a little more than stub_server is able to do; especially SSLCACertificateFile.
    # See http://ben.vandgrift.com/2011/06/17/secure_communication_rails_3.html
    #
    let(:ssl) do
      {
        cert: File.read('spec/certificates/server.crt'),
        key: File.read('spec/certificates/server.key')
      }
    end

    context 'the test server works' do
      let(:replies) { { '/hello' => [200, {}, ['World']] } }

      before do
        listening = Socket.tcp('localhost', port, connect_timeout: 1) { true } rescue false
        expect(listening).to be_falsey
      end

      it 'can connect' do
        StubServer.open(port, replies, ssl: ssl) do |server|
          server.wait
          expect(open("https://localhost:#{port}/hello", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read).to eq 'World'
        end
      end

      it 'fails on unknown paths' do
        StubServer.open(port, replies, ssl: ssl) do |server|
          server.wait
          expect { open("https://localhost:#{port}/no", ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read }.to raise_error(OpenURI::HTTPError)
        end
      end
    end
  end
end
