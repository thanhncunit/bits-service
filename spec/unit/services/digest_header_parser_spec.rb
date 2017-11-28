# frozen_string_literal: true

require 'spec_helper'

module BitsService
  describe DigestHeaderParser do
    subject { described_class.new('sha256') }

    context 'with a supported algorithm' do
      it 'returns the digest' do
        expect(subject.parse('sha256=abcdefg')).to eq('abcdefg')
      end

      context 'when the algorithm is missing' do
        it 'raises an error' do
          expect { subject.parse('=abcdefg') }.to raise_error(DigestHeaderParser::AlgorithmMissing)
        end

        context 'and the digest is missing,too' do
          it 'raises an error' do
            expect { subject.parse('=') }.to raise_error(DigestHeaderParser::UnknownFormat)
          end
        end
      end

      context 'when the digest is missing' do
        it 'raises an error' do
          expect { subject.parse('sha256=') }.to raise_error(DigestHeaderParser::DigestMissing)
        end
      end

      context 'when the header is in an unexpected format' do
        it 'raises an error' do
          expect { subject.parse('foobar') }.to raise_error(DigestHeaderParser::UnsupportedAlgorithm)
        end
      end
    end
  end
end
