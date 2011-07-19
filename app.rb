require 'sinatra'
require 'json'

get '/app.js' do
  coffee File.read(File.join('app.js.coffee'))
end

get '/' do
  File.read(File.join('app.html'))
end

post '/events' do
  content_type :json
  puts params
  {:state => params["event"]}.to_json
end
