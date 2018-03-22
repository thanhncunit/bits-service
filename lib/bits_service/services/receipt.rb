# frozen_string_literal: true

require 'pathname'
require 'find'

module BitsService
  class Receipt
    def initialize(destination_path)
      @destination_path = Pathname(destination_path)
      @digester = Digester.new
    end

    def contents
      Find.find(@destination_path).select { |e| File.file?(e) }.map do |file|
        file = Pathname(file)

        {
          'fn' => file.relative_path_from(@destination_path),
          'sha1' => @digester.digest_path(file),
          'mode' => file_mode(file),
          'size' => file.size,
        }
      end
    end

    private

    def file_mode(file_path)
      (File.stat(file_path).mode.to_s(8).to_i % 1000).to_s
    end
  end
end
