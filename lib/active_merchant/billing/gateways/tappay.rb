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
      def authorize(money, pot, options = {})
        post_data = options.merge(base_post_data)
        post_data[:details] = options[:description]
        post_data[:amount] = money
        post_data[:prime] = pot
        commit "pay-by-prime", post_data
      end

      #pot -> Prime or Token Data from Tappay
      def purchase(money, pot , options={})
        post_data = options.merge(base_post_data)
        post_data[:details] = options[:description]
        post_data[:amount] = money
        post_data[:card_key] = pot[:key]
        post_data[:card_token] = pot[:token]
        commit "pay-by-token", post_data
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
          rec_trade_id: rec_trade_id,
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
        rh = {rec_trade_id: resp["rec_trade_id"]}
        if x = resp.has_key?("card_secret")
          rh[:card_token] = x["card_token"]
          rh[:card_key] = x["card_key"]
        end
      end

      def error_code_from(response)
        unless success_from(response)
          # TODO: lookup error code for this response
        end
      end
    end
  end
end
