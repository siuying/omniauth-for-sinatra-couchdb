require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'couchrest'
require 'couchrest_model'
require 'oa-oauth'

$COUCH = CouchRest.new ENV["CLOUDANT_URL"]
$COUCH.default_database = "omniauth-for-sinatra"

class User < CouchRest::Model::Base
  use_database $COUCH.default_database

  property :uid
  property :name
  property :nickname
  timestamps!
  
  design do 
    view :by_uid
  end
end

# You'll need to customize the following line. Replace the CONSUMER_KEY 
#   and CONSUMER_SECRET with the values you got from Twitter 
#   (https://dev.twitter.com/apps/new).
use OmniAuth::Strategies::Twitter, ENV['TWITTER_CONSUMER_KEY'], ENV['TWITTER_CONSUMER_SECRET']

enable :sessions

helpers do
  def current_user
    puts "user_id: #{session[:user_id]}"
    @current_user ||= User.get(session[:user_id]) if session[:user_id]
  end
end

get '/' do
  if current_user
    # The following line just tests to see that it's working.
    #   If you've logged in your first user, '/' should load: "1 ... 1";
    #   You can then remove the following line, start using view templates, etc.
    "Hello, #{current_user.nickname}"
  else
    '<a href="/sign_up">create an account</a> or <a href="/sign_in">sign in with Twitter</a>'
    # if you replace the above line with the following line, 
    #   the user gets signed in automatically. Could be useful. 
    #   Could also break user expectations.
    # redirect '/auth/twitter'
  end
end

get '/auth/:name/callback' do
  auth = request.env["omniauth.auth"]
  puts "auth = #{auth.inspect}"
  
  user = User.find_by_uid(auth["uid"]) || User.new(:uid => auth["uid"])
  user.nickname = auth["nickname"]
  user.name = auth["name"]
  user.save!

  session[:user_id] = user.id
  redirect '/'
end

get "/auth/failure" do
  params[:message]
end

# any of the following routes should work to sign the user in: 
#   /sign_up, /signup, /sign_in, /signin, /log_in, /login
["/sign_in/?", "/signin/?", "/log_in/?", "/login/?", "/sign_up/?", "/signup/?"].each do |path|
  get path do
    redirect '/auth/twitter'
  end
end

# either /log_out, /logout, /sign_out, or /signout will end the session and log the user out
["/sign_out/?", "/signout/?", "/log_out/?", "/logout/?"].each do |path|
  get path do
    session[:user_id] = nil
    redirect '/'
  end
end