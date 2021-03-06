module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class Error < ActiveMerchantError #:nodoc:
    end

    class Response
      attr_reader :params, :message, :test, :authorization, :avs_result, :cvv_result, :pa_req, :md, :acs_url
      
      def success?
        @success
      end

      def test?
        @test
      end

      def fraud_review?
        @fraud_review
      end
      
      def three_d_secure?
        @three_d_secure
      end
      
      def initialize(success, message, params = {}, options = {})
        @success, @message, @params = success, message, params.stringify_keys
        @test = options[:test] || false
        @authorization = options[:authorization]
        @fraud_review = options[:fraud_review]
        @avs_result = if options[:avs_result].kind_of?(AVSResult)
          options[:avs_result].to_hash
        else
          AVSResult.new(options[:avs_result]).to_hash
        end

        @cvv_result = if options[:cvv_result].kind_of?(CVVResult)
          options[:cvv_result].to_hash
        else
          CVVResult.new(options[:cvv_result]).to_hash
        end
        @three_d_secure = options[:three_d_secure]
        @pa_req = options[:pa_req]
        @md = options[:md]
        @acs_url = options[:acs_url]
      end
    end

    class MultiResponse < Response
      def self.run(&block)
        new.tap(&block)
      end

      attr_reader :responses

      def initialize
        @responses = []
      end

      def process
        self << yield if(responses.empty? || success?)
      end

      def <<(response)
        if response.is_a?(MultiResponse)
          response.responses.each{|r| @responses << r}
        else
          @responses << response
        end
      end

      def success?
        @responses.all?{|r| r.success?}
      end

      %w(params message test authorization avs_result cvv_result test? fraud_review?).each do |m|
        class_eval %(
          def #{m}
            (@responses.empty? ? nil : @responses.last.#{m})
          end
        )
      end
    end
  end
end
