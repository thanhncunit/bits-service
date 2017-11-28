# frozen_string_literal: true

module BitsService
  module Blobstore
    class Blob
      CACHE_ATTRIBUTES = %i[etag last_modified created_at content_length].freeze
    end
  end
end
