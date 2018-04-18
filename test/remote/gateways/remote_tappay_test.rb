require 'test_helper'

class RemoteTappayTest < Test::Unit::TestCase

  TEST_PRIME = 'test_3a2fb2b7e892b914a03c95dd4dd5dc7970c908df67a49527c0a648b2bc9'

  def setup
    @gateway = TappayGateway.new(fixtures(:tappay))
    @amount = 100
    @prime_options = {
      prime: TEST_PRIME,
      details: "TapPay Test",
      cardholder: {
        phone_number: '0912345678',
        name: "王小明",
        email: "LittleMing@Wang.com",
        zip_code: "100",
        address: "台北市天龍區芝麻街1號1樓",
        national_id: "A123456789"
      }
    }
    @token_options = {
      details: "Tappay Token Test"
    }

  end

  def test_successful_purchase_with_prime
    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
  end

  def test_successful_purchase_by_token
    rsp = @gateway.purchase(@amount, @credit_card, @options.merge({remember: true}))
    tk = ::ActiveMerchant::Billing::TappayToken.new(token: rsp["card_secret"]["card_token"], key: rsp["card_secret"]["card_key"])
    assert response = @gateway.purchase(@amount, tk, @options)
    assert_success response
  end

end
