require_relative './base'

module BitsService
  module Routes
    class Droplets < Base
      put %r{/droplets/(.*/.*)} do |guid|
        begin
          uploaded_filepath = upload_params.upload_filepath('droplet')
          return create_from_upload(uploaded_filepath, guid) if uploaded_filepath

          source_guid = parsed_body['source_guid']
          return create_as_duplicate(source_guid, guid) if source_guid

          fail Errors::ApiError.new_from_details('InvalidDropletSource')
        ensure
          FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
        end
      end

      get %r{/droplets/(.*/.*)} do |guid|
        blob = droplet_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob

        if droplet_blobstore.local?
          if use_nginx?
            return [200, { 'X-Accel-Redirect' => blob.internal_download_url }, nil]
          else
            return send_file blob.local_path
          end
        else
          return [302, { 'Location' => blob.public_download_url }, nil]
        end
      end

      delete %r{/droplets/(.*/.*)} do |guid|
        blob = droplet_blobstore.blob(guid)
        fail Errors::ApiError.new_from_details('NotFound', guid) unless blob
        droplet_blobstore.delete_blob(blob)
        status 204
      end

      private

      def create_from_upload(uploaded_filepath, guid)
        fail Errors::ApiError.new_from_details('DropletUploadInvalid', 'a file must be provided') if uploaded_filepath.to_s == ''

        droplet_blobstore.cp_to_blobstore(uploaded_filepath, guid)
        status 201
      ensure
        FileUtils.rm_f(uploaded_filepath) if uploaded_filepath
      end

      def create_as_duplicate(source_guid, new_guid)
        blob = droplet_blobstore.blob(source_guid)
        fail Errors::ApiError.new_from_details('NotFound', source_guid) unless blob

        droplet_blobstore.cp_file_between_keys(source_guid, new_guid)
        status 201
      end

      def parsed_body
        body = request.body.read

        if body.empty?
          {}
        else
          JSON.parse(body)
        end
      rescue JSON::ParserError => e
        fail Errors::ApiError.new_from_details('MessageParseError', e.message)
      end
    end
  end
end
