require 'spec_helper'
require 'securerandom'

module Bits
  describe Routes::Buildpacks do

    let(:headers) { Hash.new }

    let(:zip_filepath) { File.join(Dir.mktmpdir, 'file.zip')}
    let(:buildpack_guid) { SecureRandom.uuid }

    let(:zip_file) do
      TestZip.create(zip_filepath, 1, 1024)
      Rack::Test::UploadedFile.new(File.new(zip_filepath))
    end

    let(:non_zip_file) do
      Rack::Test::UploadedFile.new(Tempfile.new('foo'))
    end

    let(:zip_file_sha) { Digester.new.digest_path(zip_file) }

    let(:upload_body) { { buildpack: zip_file } }

    around(:each) do |example|
      Fog.mock!
      example.run
      Fog.unmock!
    end

    after(:each) do
      FileUtils.rm_f(zip_filepath)
      FileUtils.rm_f(non_zip_file.tempfile.path)
    end

    describe 'PUT /buildpacks/:guid' do
      it 'returns HTTP status 201' do
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
        expect(last_response.status).to eq(201)
      end

      it 'stores the uploaded file to the buildpack blobstore using the correct key' do
        allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)

        blobstore = double(Bits::Blobstore::Client)
        expect_any_instance_of(Bits::BlobstoreFactory).to receive(:create_buildpack_blobstore).and_return(blobstore)

        expected_key = "#{buildpack_guid}_#{zip_file_sha}"
        expect(blobstore).to receive(:cp_to_blobstore).with(zip_filepath, expected_key)

        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'instantiates the blobstore factory with the right config' do
        expect(Bits::BlobstoreFactory).to receive(:new).with(hash_including(:buildpacks)).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'uses the blobstore factory to create a buildpack blobstore' do
        blobstore_factory = double(Bits::BlobstoreFactory)
        allow(Bits::BlobstoreFactory).to receive(:new).and_return(blobstore_factory)
        expect(blobstore_factory).to receive(:create_buildpack_blobstore).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'instantiates the upload params decorator with the right arguments' do
        expect(UploadParams).to receive(:new).with(hash_including('buildpack'), use_nginx: false).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'gets the uploaded filepath from the upload params decorator' do
        decorator = double(UploadParams)
        allow(UploadParams).to receive(:new).and_return(decorator)
        expect(decorator).to receive(:upload_filepath).with('buildpack').once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'uses the default digester' do
        expect(Digester).to receive(:new).with(no_args).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'gets the sha of the uploaded file from the digester' do
        allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
        expect_any_instance_of(Digester).to receive(:digest_path).with(zip_filepath).once
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
      end

      it 'does not leave the temporary instance of the uploaded file around' do
        allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
        put "/buildpacks/#{buildpack_guid}", upload_body, headers
        expect(File.exist?(zip_filepath)).to be_falsy
      end

      context 'when no file is being uploaded' do
        before(:each) do
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(nil)
          expect(Bits::BlobstoreFactory).to_not receive(:new)
        end

        it 'returns a corresponding error' do
          put "/buildpacks/#{buildpack_guid}", nil, headers

          expect(last_response.status).to eq(400)
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(290002)
          expect(json['description']).to match(/a file must be provided/)
        end
      end

      context 'when a non-zip file is being uploaded' do
        let(:upload_body) {{ buildpack: non_zip_file  }}

        it 'returns a corresponding error' do
          put "/buildpacks/#{buildpack_guid}", upload_body, headers

          expect(last_response.status).to eql 400
          json = MultiJson.load(last_response.body)
          expect(json['code']).to eq(290002)
          expect(json['description']).to match(/only zip files allowed/)
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          filepath = non_zip_file.tempfile.path
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(filepath)
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(File.exist?(filepath)).to be_falsy
        end
      end

      context 'when the blobstore copy fails' do
        before(:each) do
          allow_any_instance_of(Blobstore::Client).to receive(:cp_to_blobstore).and_raise('some error')
        end

        it 'return HTTP status 500' do
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(last_response.status).to eq(500)
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(File.exist?(zip_filepath)).to be_falsy
        end
      end

      context 'when the blobstore factory fails' do
        before(:each) do
          allow(BlobstoreFactory).to receive(:new).and_raise('some error')
        end

        it 'return HTTP status 500' do
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(last_response.status).to eq(500)
        end

        it 'does not leave the temporary instance of the uploaded file around' do
          allow_any_instance_of(UploadParams).to receive(:upload_filepath).and_return(zip_filepath)
          put "/buildpacks/#{buildpack_guid}", upload_body, headers
          expect(File.exist?(zip_filepath)).to be_falsy
        end
      end

    end
  end
end
