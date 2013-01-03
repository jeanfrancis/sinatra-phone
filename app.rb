# A very simple app to make and receive phone calls
# in a webbrowser usering webrtc and the ATT webrtc apis.

$stdout.sync = true
Bundler.setup
require 'sinatra'
require "sinatra/cookies"
require "sinatra/reloader"  if ENV['RACK_ENV']=='development'
require 'yajl/json_gem'
require 'pry'               if ENV['RACK_ENV']=='development'
require 'omniauth-att'
require 'omniauth-facebook'
require 'net/http'

require File.dirname(__FILE__)+"/att.rb"

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
    erb :authorized
  end
  
  get "/phone" do
    @version=params[:version] || "a3"
    erb :phone
  end
  
  get "/candybar" do
    @version=params[:version] || "a3"
    erb :candybar
  end
  
  #  proxy path to avoid cross origin issues
  post "/proxy" do
    uri = URI.parse(params[:url])
    response = Net::HTTP.post_form(uri, {})
    status response.code
    #TODO headers = response.headers
    response.body.to_s
  end
 
end