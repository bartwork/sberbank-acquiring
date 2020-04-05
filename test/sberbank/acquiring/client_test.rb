# frozen_string_literal: true

require 'test_helper'

module Sberbank
  module Acquiring
    class ClientTest < Minitest::Test
      COMMAND_PATH_MAPPING = {
        deposit: '/payment/rest/deposit.do',
        get_order_status_extended: '/payment/rest/getOrderStatusExtended.do',
        payment: '/payment/rest/payment.do',
        payment_sber_pay: '/payment/rest/paymentSberPay.do',
        refund: '/payment/rest/refund.do',
        register: '/payment/rest/register.do',
        register_pre_auth: '/payment/rest/registerPreAuth.do',
        reverse: '/payment/rest/reverse.do',
        verify_enrollment: '/payment/rest/verifyEnrollment.do'
      }.freeze

      def test_initialize_builds_parameters_convertor_with_username_and_password
        expected_username = Object.new
        expected_password = Object.new
        client = Client.new(username: expected_username, password: expected_password)
        convertor = client.instance_variable_get(:@parameters_convertor)

        assert_kind_of CommandParametersConvertor, convertor
        assert_equal convertor.default_params, 'userName' => expected_username, 'password' => expected_password
      end

      def test_initialize_builds_parameters_convertor_with_token
        expected_token = Object.new
        client = Client.new(token: expected_token)

        convertor = client.instance_variable_get(:@parameters_convertor)
        assert_kind_of CommandParametersConvertor, convertor
        assert_equal convertor.default_params, 'token' => expected_token
      end

      def test_test_default
        client = Client.new(token: Object.new)

        refute client.test?
        refute client.test
      end

      def test_test
        client = Client.new(token: Object.new, test: true)
        assert client.test?
        assert client.test
      end

      COMMAND_PATH_MAPPING.each do |command, path|
        define_method "test_#{command}" do
          client = Client.new
          expected_params = Object.new

          execute_mock = Minitest::Mock.new
          execute_mock.expect(:call, nil, [{ path: path, params: expected_params }])

          client.stub(:execute, execute_mock) { client.public_send(command, expected_params) }
        end
      end

      def test_execute
        stub_request(:post, 'https://securepayments.sberbank.ru/payment/rest/register.do').
          with(
            body: {
              'amount' => '12345',
              'jsonParams' => '{"email":"user@example.com"}',
              'orderNumber' => 'order#1',
              'returnUrl' => 'https://return.example.com/sberbank_payments/success',
              'token' => 'token'
            },
            headers: {
              content_type: 'application/x-www-form-urlencoded'
            }
          ).
          to_return(body: { 'orderId' => 'orderId', 'errorCode' => 0 }.to_json)

        client = Client.new(token: 'token')
        response = client.execute(
          path: '/payment/rest/register.do',
          params: {
            amount: 12345,
            json_params: { email: 'user@example.com'},
            order_number: 'order#1',
            return_url: 'https://return.example.com/sberbank_payments/success'
          }
        )

        assert_kind_of CommandResponseDecorator, response
        assert_equal 'orderId', response.order_id
        assert_equal 0, response.error_code
      end
    end
  end
end
