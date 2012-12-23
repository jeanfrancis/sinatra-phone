# A very simple app to make and receive phone calls
# in a webbrowser usering webrtc and the ATT webrtc apis.

$stdout.sync = true
Bundler.setup
require 'sinatra'
require "sinatra/cookies"
require "sinatra/reloader" if ENV['RACK_ENV']=='development'
require "redis"
require 'yajl/json_gem'
require 'pry' if ENV['RACK_ENV']=='development'
require 'omniauth-att'
require 'omniauth-facebook'
require 'net/http'

require File.dirname(__FILE__)+"/att.rb"
redis = Redis.new # works with local redis server
set :raise_errors, Proc.new { false }
set :show_exceptions, false
puts "Redis Client Created"

class WebrtcPhone < Sinatra::Base
  helpers Sinatra::Cookies
  configure do
    disable :protection
    set :layout, :layout
    use Rack::Session::Cookie, :key => 'sinatra-webrtc',
                               :path => '/',
                               :expire_after => 14400, # In seconds
                               :secret => 'some-random-s3cr3t-string'
     use OmniAuth::Builder do
       # provider :facebook, (ENV['FACEBOOK_CLIENT_ID']||'290594154312564'),(ENV['FACEBOOK_CLIENT_SECRET']||'a26bcf9d7e254db82566f31c9d72c94e')
       provider :att, ENV['ATT_CLIENT_ID'], ENV['ATT_CLIENT_SECRET'], :site=>ENV['ATT_BASE_DOMAIN'], :callback_url => ENV['ATT_REDIRECT_URI'], :scope=>"profile,webrtc"
     end
  end
  configure :development do
    register Sinatra::Reloader
  end


  get "/" do
    erb "<div class='input-block-level form-signin'><a href='/auth/att' class='btn btn-primary btn-large input-block-level' >Login</a></div>", :layout=>:layout
  end

  get '/auth/:provider/callback' do
    @access_token   = request.env['omniauth.auth']['credentials']['token']
    @refresh_token  = request.env['omniauth.auth']['credentials']['refresh_token']
    @current_user   = request.env['omniauth.auth']
    session[:uid]   = request.env['omniauth.auth']['uid']  # store thhe uid in the session so we can correlate server and client session if needed
    session[:phone_number] = @current_user['extra']['raw_info']['conference_number'] || @current_user['extra']['raw_info']['phone_number']
    # uncomment below if you prefer to store this information in cookies instead of localstorage
    # response.set_cookie("phone_number",  {:value => session[:phone_number], :path=>"/phone"})
    # response.set_cookie("access_token",  {:value => @access_token, :path=>"/phone"})
    # response.set_cookie("refresh_token", {:value => @refresh_token, :expiration => Time.now.to_i + 94608000, :path=>"/phone"})
    erb :authorized
    # redirect "/phone"  # uncomment this and remove obove erb line if you prefer to redirect straight to your target destination
  end
  
  get "/phone" do
    erb :phone
  end
  
  # to select a specific version
  get "/phone/v:version" do
    erb "phone_v#{params[:version]}"
  end
  
  #  proxy path to avoid cross origin issues
  post "/proxy" do
    uri = URI.parse(params[:url])
    response = Net::HTTP.post_form(uri, {})
    status response.code
    #TODO headers = response.headers
    response.body.to_s
  end
  
    # 
    # get "/authorize" do
    #   erb "<div class='well'><a href='#{ATT.authorize_url('webrtc,profile,messages,geo,locker,addressbook')}' class='btn btn-primary'>Login</a></div>", :layout=>:layout
    # end
    # # Receive the oauth callback, and exchange the code for an access token
    # get '/authorized' do
    #   if params[:code]
    #     access_token = ATT.exchnage_code_for_access_token(params[:code])
    #     response.set_cookie('access_token', access_token )
    #     "access_token = #{access_token}"
    #   else
    #     raise 400, "#{params[:error]} : #{params[:error_reason]}"
    #   end
    # end
  
end