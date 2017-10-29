 # -*- encoding : utf-8 -*-
require "ant/version"
require "openssl"
require "net/http"
require "net/https"
require "uri"
require "json"
require "addressable/uri"
require 'rest-client'

module Ant

  class Coins
    BTC = 'BTC'
    LTC = 'LTC'
    ETH = 'ETH'
    ZEC = 'ZEC'
  end

  class PaymentType
    PAYOUT = 'payout'
    PPS = 'PPS'
    PPLNS = 'PPLNS'
    P2P = 'P2P'
  end

  class API
    attr_accessor :api_key, :username, :nonce_v, :api_secret

    def initialize(username, api_key, api_secret)
      self.username = username
      self.api_key = api_key
      self.api_secret = api_secret
    end

    def api_call(method, param = {}, priv = false, is_json = true)
      url = "https://www.antpool.com/api/#{ method }"
      if priv
        self.nonce
        param.merge!(:key => self.api_key, :signature => self.signature.to_s.upcase, :nonce => self.nonce_v)
      end
      answer = self.post(url, param)

      # unfortunately, the API does not always respond with JSON, so we must only
      # parse as JSON if is_json is true.
      if is_json
        JSON.parse(answer)
      else
        answer
      end
    end

    def account(coin = Coins::BTC)
      self.api_call('account.htm', { :coin => coin }, true)
    end

    def hashrate(coin = Coins::BTC)
      self.api_call('hashrate.htm', { :coin => coin }, true)
    end

    def pool_stats(coin = Coins::BTC)
      self.api_call('poolStats.htm', { :coin => coin }, true)
    end

    def workers(coin = Coins::BTC, pageEnable = 1, page = 1, pageSize = 10)
      self.api_call('workers.htm', { :coin => coin, :pageEnable => pageEnable, :page => page, :pageSize => pageSize }, true)
    end

    def payment_history(coin = Coins::BTC, type = PaymentType::PAYOUT, pageEnable = 1, page = 1, pageSize = 10)
      self.api_call('paymentHistory.htm', { :coin => coin, :type => type, :pageEnable => pageEnable, :page => page, :pageSize => pageSize }, true)
    end

    def nonce
      self.nonce_v = (Time.now.to_f * 1000000).to_i.to_s
    end

    def signature
      str = self.username + self.api_key + self.nonce_v
      OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), self.api_secret, str)
    end

    def post(url, param)
      # 由于服务器采用不安全openssl
      # uri = URI.parse(url)
      # https = Net::HTTP.new(uri.host, uri.port)
      # https.use_ssl = false
      # params = Addressable::URI.new
      # params.query_values = param
      # https.post(uri.path, params.query).body
      RestClient.post(url, param)
    end
  end
end
