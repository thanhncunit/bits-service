require 'spec_helper'

describe 'sign', type: :integration do
  before(:all) do
    @root_dir = Dir.mktmpdir

    config = {
      droplets: {
        directory_key: 'directory-key',
        fog_connection: {
          provider: 'local',
          local_root: @root_dir
        }
      },
      nginx: {
        use_nginx: false
      },
      public_endpoint: 'bits.example.com',
      secret: '12345'
    }

    start_server(config)
  end

  after(:all) do
    stop_server
    FileUtils.rm_rf(@root_dir)
  end

  describe 'GET /sign/some/path' do
    it 'returns HTTP status code 200' do
      response = make_get_request('/sign/some/path')
      expect(response.code).to eq 200
    end

    it 'signs a url' do
      response = make_get_request('/sign/some/path')

      uri = URI.parse(response.body)
      expect(uri).to be

      expect(uri.host).to eq 'bits.example.com'
      expect(response.body).to match /md5=.+/
      expect(response.body).to match /expires=\d+/
    end
  end
end
