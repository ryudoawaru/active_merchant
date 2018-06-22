require 'json'
module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class TappayGateway < Gateway
      self.test_url = 'https://sandbox.tappaysdk.com'
      self.live_url = 'https://prod.tappaysdk.com'

      URIS = {
        :"pay-by-prime" => "/tpc/payment/pay-by-prime",
        :"pay-by-token" => "/tpc/payment/pay-by-token",
        :refund => "/tpc/transaction/refund"
      }

      self.supported_countries = ['TW']
      self.default_currency = 'TWD'
      self.supported_cardtypes = [:visa, :master, :american_express, :discover]

      self.homepage_url = 'http://www.tappay.com/'
      self.display_name = 'Tappay'

      STANDARD_ERROR_CODE_MAPPING = {}

      def initialize(options = {})
        @merchant_id = options[:merchant_id]
        @partner_key = options[:partner_key]
        super
      end

      # 這段是 pay by prime
      def authorize(money, prime_or_token, options = {})
        post_data = options.merge(base_post_data)
        post_data[:details] = options[:description]
        post_data[:amount] = money
        if prime_or_token.is_a? Hash
          post_data[:card_key] = prime_or_token[:key]
          post_data[:card_token] = prime_or_token[:token]
          commit "pay-by-token", post_data
        else
          post_data[:prime] = prime_or_token
          commit "pay-by-prime", post_data
        end
      end

      #prime_or_token -> Prime or Token Data from Tappay
      def purchase(money, prime_or_token , options={})
        authorize(money, prime_or_token , options)
      end

      def base_post_data
        {
          partner_key: @partner_key,
          merchant_id: @merchant_id,
          currency: "TWD"
        }
      end

      def void(rec_trade_id, options = {})
        refund 0, rec_trade_id, options
      end

      def refund(money, rec_trade_id, options={})
        params = {
          partner_key: @partner_key,
          rec_trade_id: rec_trade_id
        }
        params[:amount] = money if money > 0
        commit('refund', params)
      end

      def supports_scrubbing?
        true
      end

      def scrub(transcript)
        transcript
      end

      private

      def req_headers
        @req_headers ||= {
          "Content-Type" => 'application/json',
          "x-api-key" => @partner_key
        }
      end

      def parse(body)
        JSON.parse(body)
      end

      #Response: success, message, params = {}, options = {}
      def commit(action, parameters)
        url = File.join (test? ? test_url : live_url), URIS[action.to_sym]
        response = parse(ssl_post(url, parameters.to_json, req_headers))
        is_success = success_from(response)
        Response.new(
          is_success,
          message_from(response),
          response,
          authorization: is_success ? response_authorization(response) : nil,
          test: test?,
          error_code: error_code_from(response)
        )
      end

      def test?
        @options[:test_mode]
      end

      def success_from(response)
        response["status"].to_i == 0
      end

      def message_from(response)
        response["msg"]
      end

      def response_authorization(resp)
        resp["rec_trade_id"]
      end

      def error_code_from(response)
        unless success_from(response)
          # TODO: lookup error code for this response
        end
      end
    end
  end
end
