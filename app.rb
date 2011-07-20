require 'sinatra'
require 'json'

@@shouts = ["inaugural wassap"]

get '/app.js' do
  coffee File.read('app.js.coffee')
end

get '/' do
  File.read('app.html')
end

post '/events' do
  content_type :json
  if params["message"]["cmd"] == "shout"
    @@shouts = @@shouts.unshift params["message"]["text"]
  end
  {:shouts => @@shouts.map{|s| {:shout => s}}}.to_json
end
