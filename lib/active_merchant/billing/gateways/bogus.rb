module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    # Bogus Gateway
    class BogusGateway < Gateway
      AUTHORIZATION = '53433'

      SUCCESS_MESSAGE = "Bogus Gateway: Forced success"
      FAILURE_MESSAGE = "Bogus Gateway: Forced failure"
      THREE_D_SECURE_MESSAGE = "Bogus Gateway: Requires additional 3D secure authentication"
      ERROR_MESSAGE = "Bogus Gateway: Use CreditCard number ending in 1 for success, 2 for exception and anything else for error"
      CREDIT_ERROR_MESSAGE = "Bogus Gateway: Use CreditCard number ending in 1 for success, 2 for exception and anything else for error"
      UNSTORE_ERROR_MESSAGE = "Bogus Gateway: Use trans_id ending in 1 for success, 2 for exception and anything else for error"
      CAPTURE_ERROR_MESSAGE = "Bogus Gateway: Use authorization number ending in 1 for exception, 2 for error and anything else for success"
      VOID_ERROR_MESSAGE = "Bogus Gateway: Use authorization number ending in 1 for exception, 2 for error and anything else for success"
      REFUND_ERROR_MESSAGE = "Bogus Gateway: Use trans_id number ending in 1 for exception, 2 for error and anything else for success"
      
      THREE_D_MD = 'md'
      THREE_D_PA_REQ = 'pa_req'
      THREE_D_PA_RES = 'pa_res'
      THREE_D_ACS_URL = 'https://domain.com/3d_secure_page'

      self.supported_countries = ['US']
      self.supported_cardtypes = [:bogus]
      self.supports_3d_secure = true
      self.homepage_url = 'http://example.com'
      self.display_name = 'Bogus'

      def authorize(money, credit_card_or_reference, options = {})
        money = amount(money)
        case normalize(credit_card_or_reference)
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {:authorized_amount => money}, :test => true, :authorization => AUTHORIZATION )
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:authorized_amount => money, :error => FAILURE_MESSAGE }, :test => true)
        when /4$/
          Response.new(false, THREE_D_SECURE_MESSAGE, {:authorized_amount => money.to_s}, :three_d_secure => true, :pa_req => THREE_D_PA_REQ, :md => THREE_D_MD, :acs_url => THREE_D_ACS_URL, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

      def purchase(money, credit_card_or_reference, options = {})
        money = amount(money)
        case normalize(credit_card_or_reference)
        when /1$/, AUTHORIZATION
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true)
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE },:test => true)
        when /4$/
          Response.new(false, THREE_D_SECURE_MESSAGE, {:paid_amount => money.to_s}, :three_d_secure => true, :pa_req => THREE_D_PA_REQ, :md => THREE_D_MD, :acs_url => THREE_D_ACS_URL, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

      def recurring(money, credit_card_or_reference, options = {})
        money = amount(money)
        case normalize(credit_card_or_reference)
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true)
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE },:test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

      def credit(money, credit_card_or_reference, options = {})
        if credit_card_or_reference.is_a?(String)
          deprecated CREDIT_DEPRECATION_MESSAGE
          return refund(money, credit_card_or_reference, options)
        end

        money = amount(money)
        case normalize(credit_card_or_reference)
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true )
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, CREDIT_ERROR_MESSAGE
        end
      end
 
      def three_d_complete(pa_res, md)
        if pa_res == THREE_D_PA_RES && md == THREE_D_MD
          Response.new(true, SUCCESS_MESSAGE, {}, :test => true, :authorization => AUTHORIZATION)
        else
          Response.new(false, FAILURE_MESSAGE, {},:test => true)
        end
      end


      def refund(money, reference, options = {})
        money = amount(money)
        case reference
        when /1$/
          raise Error, REFUND_ERROR_MESSAGE
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true)
        end
      end

      def capture(money, reference, options = {})
        money = amount(money)
        case reference
        when /1$/
          raise Error, CAPTURE_ERROR_MESSAGE
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:paid_amount => money, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:paid_amount => money}, :test => true)
        end
      end

      def void(reference, options = {})
        case reference
        when /1$/
          raise Error, VOID_ERROR_MESSAGE
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:authorization => reference, :error => FAILURE_MESSAGE }, :test => true)
        else
          Response.new(true, SUCCESS_MESSAGE, {:authorization => reference}, :test => true)
        end
      end

      def store(credit_card_or_reference, options = {})
        case normalize(credit_card_or_reference)
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {:billingid => '1'}, :test => true, :authorization => AUTHORIZATION)
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:billingid => nil, :error => FAILURE_MESSAGE }, :test => true)
        else
          raise Error, ERROR_MESSAGE
        end
      end

      def unstore(reference, options = {})
        case reference
        when /1$/
          Response.new(true, SUCCESS_MESSAGE, {}, :test => true)
        when /2$/
          Response.new(false, FAILURE_MESSAGE, {:error => FAILURE_MESSAGE },:test => true)
        else
          raise Error, UNSTORE_ERROR_MESSAGE
        end
      end

      private

      def normalize(credit_card_or_reference)
        if credit_card_or_reference.respond_to?(:number)
          credit_card_or_reference.number
        else
          credit_card_or_reference.to_s
        end
      end
    end
  end
end
