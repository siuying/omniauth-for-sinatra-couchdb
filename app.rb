%w(rubygems oa-oauth dm-core dm-sqlite-adapter dm-migrations sinatra).each { |dependency| require dependency }

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/database.db")

class User
  include DataMapper::Resource
  property :id,         Serial
  property :uid,        String
  property :name,       String
  property :nickname,   String
  property :created_at, DateTime
end

DataMapper.finalize
DataMapper.auto_upgrade!

# You'll need to customize the following line. Replace the CONSUMER_KEY and CONSUMER_SECRET with the values you got from Twitter (https://dev.twitter.com/apps/new).
use OmniAuth::Strategies::Twitter, 'CONSUMER_KEY', 'CONSUMER_SECRET'

enable :sessions

helpers do
  def current_user
    @current_user ||= User.get(session[:user_id]) if session[:user_id]
  end
end

get '/' do
  if current_user
    # the following line just tests to see that it's working. If you've logged in your first user, '/' should load: "1 ... 1"; You can then remove the following line, start using view templates, etc.
    current_user.id.to_s + " ... " + session[:user_id].to_s 
  else
    '<a href="/sign_up">create an account</a> or <a href="/sign_in">sign in with Twitter</a>'
    # if you replace the above line with the following line, the user gets signed in automatically. Could be useful. Could also break user expectations.
    # redirect '/auth/twitter'
  end
end

get '/auth/:name/callback' do
  auth = request.env["omniauth.auth"]
  user = User.first_or_create({ :uid => auth["uid"]}, { :uid => auth["uid"], :nickname => auth["user_info"]["nickname"], :name => auth["user_info"]["name"], :created_at => Time.now })
  session[:user_id] = user.id
  redirect '/'
end

get %r{/[/log|sign_?up|in/]} do
  redirect '/auth/twitter'
end

get %r{/[/log|sign_?out/]} do
  session[:user_id] = nil
  redirect '/'
end