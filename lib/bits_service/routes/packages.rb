# frozen_string_literal: true

require 'digest'
require_relative './base'
require 'English'

module BitsService
  module Routes
    class Packages < Base
      include Errors
      include Helpers::CCUpdaterFactory

      put '/packages/:guid' do |guid|
        uploaded_filepath = upload_params.upload_filepath('bits')
        uploaded_filepath = upload_params.upload_filepath('package') unless uploaded_filepath
        source_guid = parsed_body['source_guid'] unless uploaded_filepath

        if uploaded_filepath.nil? && source_guid.nil?
          fail(ApiError.new_from_details('InvalidPackageSource').tap { |err|
            with_metric('failed', ignore_errors: true) { cc_updater.failed(guid, err.to_s) }
          })
        end

        begin
          if uploaded_filepath
            with_metric('processing_upload') { cc_updater.processing_upload(guid) }
            digests = create_from_upload(uploaded_filepath, guid)
            with_metric('ready') { cc_updater.ready(guid, digests) }
          elsif source_guid
            create_as_duplicate(source_guid, guid)
            with_metric('ready') { cc_updater.ready(guid) }
          end
        rescue
          with_metric('failed', ignore_errors: true) { cc_updater.failed(guid, $ERROR_INFO.to_s) }
          raise
        end
        content_type :json
        {
          guid: guid,
          type: "bits",
          data: {
            checksum: {
              type: "sha256",
            },
          },
          state: "READY",
          created_at: "2015-11-13T17:02:56Z",
          updated_at: "2016-06-08T16:41:26Z",
          links: {
            self: {
              href: "https://api.v3-push-bosh-lite.freeddns.org/v3/packages/#{guid}"
            },
            upload: {
              href: "https://api.example.org/v3/packages/44f7c078-0934-470f-9883-4fcddc5b8f13/upload",
              method: "POST"
            },
            download: {
              href: "https://api.v3-push-bosh-lite.freeddns.org/v3/packages/#{guid}/download",
              method: "GET"
            },
          }
        }.to_json

      end

      get '/packages/:guid' do |guid|
        blob = packages_blobstore.blob(guid)
        fail ApiError.new_from_details('ResourceNotFound', guid) unless blob

        if packages_blobstore.local?
          if use_nginx?
            return [200, { 'X-Accel-Redirect' => blob.internal_download_url }, nil]
          else
            return send_file blob.local_path
          end
        else
          return [302, { 'Location' => blob.public_download_url }, nil]
        end
      end

      delete '/packages/:guid' do |guid|
        blob = packages_blobstore.blob(guid)
        fail ApiError.new_from_details('ResourceNotFound', guid) unless blob

        packages_blobstore.delete_blob(blob)
        status 204
      end

      def create_from_upload(uploaded_filepath, target_guid)
        fail ApiError.new_from_details('PackageUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s.empty?

        statsd.time 'packages-cp_to_blobstore-time.sparse-avg' do
          packages_blobstore.cp_to_blobstore(uploaded_filepath, target_guid)
        end

        status 201

        {
          sha1: Digest::SHA1.file(uploaded_filepath).hexdigest,
          sha256: Digest::SHA256.file(uploaded_filepath).hexdigest
        }
      rescue Errno::ENOSPC
        fail ApiError.new_from_details('NoSpaceOnDevice')
      ensure
        FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
      end

      def create_as_duplicate(source_guid, target_guid)
        blob = packages_blobstore.blob(source_guid)
        fail ApiError.new_from_details('ResourceNotFound', "Could not find package: #{source_guid}") unless blob

        packages_blobstore.cp_file_between_keys(source_guid, target_guid)
        status 201
      rescue Errno::ENOSPC
        fail ApiError.new_from_details('NoSpaceOnDevice')
      end

      def parsed_body
        body = request.body.read

        if body.empty?
          {}
        else
          JSON.parse(body)
        end
      rescue JSON::ParserError => e
        fail ApiError.new_from_details('MessageParseError', e.message)
      end

      def cc_updater
        @cc_updater ||= produce_cc_updater(config[:cc_updates], mtls_client)
      end

      def with_metric(metric, options={})
        try_update_status(options) do
          statsd.time("packages-cc_updater_#{metric}-time.sparse-avg") do
            yield
          end
        end
      end

      def try_update_status(ignore_errors: false)
        yield
      rescue CCUpdater::UpdateError
        fail ApiError.new_from_details('CannotUpdateExistingPackage') unless ignore_errors
      rescue CCUpdater::ResourceNotFoundError
        fail ApiError.new_from_details('ResourceNotFound', $ERROR_INFO.to_s) unless ignore_errors
      end
    end
  end
end
