require 'uri'
require 'net/http'
require 'aws-sigv4'
require 'dotenv'
require './refresh_token.rb'
Dotenv.load

module Net::HTTPHeader
  def capitalize(name)
    name
  end
  private :capitalize
end

# Request Values
access_token = get_access_token
access_key_id = ENV['IAM_ACCESS_KEY']
secret_access_key = ENV['IAM_SECRET_ACCESS_KEY']
method = 'GET'
service = 'execute-api'
host = 'sandbox.sellingpartnerapi-na.amazon.com'
region = 'us-east-1'
endpoint = 'https://' + host
path = '/vendor/orders/v1/purchaseOrders'
t = Time.now.utc
@query_hash = {
  'limit' => 54,
  'createdAfter' => (t - 24*60*60*7).strftime("%Y-%m-%dT%H:%M:%S").gsub(':', '%3A'),
  'createdBefor' => t.strftime("%Y-%m-%dT%H:%M:%S").gsub(':', '%3A'),
  'sortOrder' => 'DESC'
}

def formatted_query
  list = []
  @query_hash.each_pair do |k, v|
    k = k.downcase
    list << [k, v]
  end

  list.sort.map do |k, v|
    "#{k}=#{v}"
  end.join('&')
end

query = formatted_query
url = URI(endpoint + path + '?' + query)

signer = Aws::Sigv4::Signer.new(
  service: service,
  region: region,
  access_key_id: access_key_id,
  secret_access_key: secret_access_key
)

signature = signer.sign_request(
  http_method: method,
  url: url
)

req = Net::HTTP::Get.new(url)
req['host'] = signature.headers['host']
# req['x-amz-access-token'] = signature.headers['x-amz-access-token']
req['x-amz-access-token'] = access_token
req['x-amz-date'] = signature.headers['x-amz-date']
req['x-amz-content-sha256'] = signature.headers['x-amz-content-sha256']
req['Authorization'] = signature.headers['authorization']

https = Net::HTTP.new(url.host, url.port)
https.use_ssl = true

res = https.request(req)

puts res.read_body
