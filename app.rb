require 'sinatra'
require 'json'

get '/app.js' do
  coffee File.read(File.join('app.js.coffee'))
end

get '/' do
  File.read(File.join('app.html'))
end

get '/events' do
  content_type :json
  {:state => 'message_received'}.to_json
end
