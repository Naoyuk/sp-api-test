require "uri"
require "net/http"
require 'json'
require 'dotenv'
Dotenv.load

def get_access_token
  url = URI("https://api.amazon.com/auth/o2/token")

  https = Net::HTTP.new(url.host, url.port)
  https.use_ssl = true

  access_key = ENV['AWS_ACCESS_KEY_ID']
  secret_key = ENV['AWS_SECRET_ACCESS_KEY']
  refresh_token = ENV['DEV_CENTRAL_REFRESH_TOKEN']

  request = Net::HTTP::Post.new(url)
  request["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8"
  request.body = "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{access_key}&client_secret=#{secret_key}"

  response = https.request(request)
  JSON.parse(response.body)['access_token']
end
