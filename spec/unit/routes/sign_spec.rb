require 'spec_helper'

module BitsService
  module Routes
    describe Sign do
      let(:config) do
        {
          secret: 'geh3im',
          public_endpoint: 'public-test-endpoint'
        }
      end

      around(:each) do |example|
        config_filepath = create_config_file(config)
        BitsService::Environment.load_configuration(config_filepath)

        example.run

        FileUtils.rm_f(config_filepath)
      end

      describe 'GET /sign' do
        let(:time_of_request) { Time.mktime(2016) }
        let(:time_of_expiry) { time_of_request.to_i + 3600 }

        it 'signs the passed URL' do
          allow(Time).to receive(:now).and_return(time_of_request)

          get '/sign/foo/bar'

          expect(last_response.ok?).to be true
          expect(last_response.body).to start_with "http://#{config[:public_endpoint]}"
          expect(URI.parse(last_response.body).query).to \
            eq "md5=69X9s1ispO_hSGkayAT_3A&expires=#{time_of_expiry}"
        end
      end
    end
  end
end
