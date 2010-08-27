require 'helper'

class TestNetwork < Test::Unit::TestCase
  
  context 'assuming a bad network' do

    should 'handle connection refused' do
      assert_raise Dalli::NetworkError do
        dc = Dalli::Client.new 'localhost:19123'
        dc.get 'foo'
      end
    end
    
    context 'with a fake server' do

      should 'handle connection reset' do
        memcached_mock(lambda {|sock| sock.close }) do
          assert_error Dalli::NetworkError, /ECONNRESET/ do
            dc = Dalli::Client.new('localhost:19123')
            dc.get('abc')
          end
        end
      end

      should 'handle malformed response' do
        memcached_mock(lambda {|sock| sock.write('123') }) do
          assert_error Dalli::NetworkError, /EOFError/ do
            dc = Dalli::Client.new('localhost:19123')
            dc.get('abc')
          end
        end
      end

      should 'handle connect timeouts' do
        memcached_mock(lambda {|sock| sleep(0.6); sock.close }, :delayed_start) do
          assert_error Dalli::NetworkError, /Timeout::Error/ do
            dc = Dalli::Client.new('localhost:19123')
            dc.get('abc')
          end
        end
      end

      should 'handle read timeouts' do
        memcached_mock(lambda {|sock| sleep(0.6); sock.write('giraffe') }) do
          assert_error Dalli::NetworkError, /Timeout::Error/ do
            dc = Dalli::Client.new('localhost:19123')
            dc.get('abc')
          end
        end
      end

    end

  end
end