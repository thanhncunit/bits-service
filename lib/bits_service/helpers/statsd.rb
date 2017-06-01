module BitsService
  module Helpers
    module StatsdHelper
      def statsd
        @statsd ||= Statsd.new 'localhost', 8125
      end
    end
  end
end
