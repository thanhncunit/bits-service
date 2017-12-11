# frozen_string_literal: true

require 'spec_helper'
require 'bits_service/services/blobstore/null_client'
require_relative 'client_shared'

module BitsService
  module Blobstore
    describe Client do
      subject(:client) { Client.new(NullClient.new) }
      let(:deletable_blob) { double }

      it_behaves_like 'a blobstore client'
    end
  end
end
