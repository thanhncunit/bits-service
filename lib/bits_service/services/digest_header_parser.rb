# frozen_string_literal: true

module BitsService
  class DigestHeaderParser
    Error = Class.new(StandardError)
    UnknownFormat = Class.new(Error)
    ValueMissing = Class.new(Error)
    AlgorithmMissing = Class.new(Error)
    DigestMissing = Class.new(Error)

    class UnsupportedAlgorithm < Error
      def initialize(offending)
        super("#{offending} is not a supported digest algorithm")
      end
    end

    def initialize(algorithm)
      @algorithm = algorithm
    end

    def parse(header)
      raise ValueMissing if header.to_s.empty?

      algorithm, digest = header.split('=')

      raise UnknownFormat if algorithm.to_s.empty? && digest.to_s.empty?
      raise AlgorithmMissing if algorithm.to_s.empty?
      raise UnsupportedAlgorithm.new(algorithm) if algorithm.downcase != @algorithm.downcase
      raise DigestMissing if digest.to_s.empty?

      digest
    end
  end
end
