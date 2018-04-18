module ActiveMerchant
  module Billing
    class TappayToken
      attr_accessor :key, :token
      def initialize(key, token)
        @key, @token = key, token
      end
    end
  end
end
