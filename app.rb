# A very simple app to make and receive phone calls
# in a webbrowser usering webrtc and the ATT webrtc apis.

$stdout.sync = true
Bundler.setup
require 'sinatra'
require "sinatra/reloader" if ENV['RACK_ENV']=='development'
require "redis"
require 'yajl/json_gem'
require 'pry' if ENV['RACK_ENV']=='development'
require 'omniauth-att'
require 'omniauth-facebook'

require File.dirname(__FILE__)+"/att.rb"
redis = Redis.new # works with local redis server
set :raise_errors, Proc.new { false }
set :show_exceptions, false
puts "Redis Client Created"

class WebrtcPhone < Sinatra::Base
  use Rack::Session::Cookie
  
  use OmniAuth::Builder do
    provider :facebook, (ENV['FACEBOOK_CLIENT_ID']||'290594154312564'),(ENV['FACEBOOK_CLIENT_SECRET']||'a26bcf9d7e254db82566f31c9d72c94e')
    provider :att, ENV['ATT_CLIENT_ID'], ENV['ATT_CLIENT_SECRET'], :site=>ENV['ATT_BASE_DOMAIN'], :callback_url => ENV['ATT_REDIRECT_URI'], :scope=>"profile,webrtc"
  end

  get "/" do
    erb "<div class='input-block-level form-signin'><a href='/auth/att' class='btn btn-primary input-block-level' >Login</a></div>", :layout=>:layout
  end

  get '/auth/:provider/callback' do
    @access_token = request.env['omniauth.auth']['credentials']['token']
    response.set_cookie("access_token", @access_token)
    session[:username] = request.env['omniauth.auth']['info']['name']
    session[:uid]=request.env['omniauth.auth']['uid']
    phone_number = request.env['omniauth.auth']['extra']['raw_info']['conference_number'] || request.env['omniauth.auth']['extra']['raw_info']['phone_number']
    session[:phone_number]=phone_number
    response.set_cookie("phone_number", phone_number)
    session[:refresh_token] = request.env['omniauth.auth']['credentials']['refresh_token']
    redirect "/phone"
    # erb "<h1>#{params[:provider]}</h1>
    #      <pre>#{JSON.pretty_generate(request.env['omniauth.auth'])}</pre>", :layout=>:layout
  end
  
  get "/phone" do
    erb :phone
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