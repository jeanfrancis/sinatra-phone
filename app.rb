# A very simple app to make and receive phone calls
# in a webbrowser usering webrtc and the ATT webrtc apis.

$stdout.sync = true
Bundler.setup
require 'sinatra'
require "sinatra/reloader" #if development?
require "redis"
require 'yajl/json_gem'
require 'pry' #if development?

require File.dirname(__FILE__)+"/att.rb"
redis = Redis.new # works with local redis server
set :raise_errors, Proc.new { false }
set :show_exceptions, false
puts "Redis Client Created"

class WebrtcPhone < Sinatra::Base
  use Rack::Session::Cookie
  
  # use OmniAuth::Builder do
  #   provider :facebook, (ENV['FACEBOOK_CLIENT_ID']||'290594154312564'),(ENV['FACEBOOK_CLIENT_SECRET']||'a26bcf9d7e254db82566f31c9d72c94e')
  #   provider :att, ENV['ATT_CLIENT_ID'], ENV['ATT_CLIENT_SECRET'], :site=>ENV['ATT_BASE_DOMAIN'], :callback_url => "http://localhost:5900/users/auth/att/callback", :scope=>"profile,webrtc"
  # end
  
  ATT = Att.new({
    :client_id      => (ENV['ATT_CLIENT_ID']      || '789b0629cd077880581442abc917ead5'),
    :client_secret  => (ENV['ATT_CLIENT_SECRET']  || '005e25e83c5e1f12'),
    :redirect_uri   => (ENV['ATT_REDIRECRT_URI']  || 'http://localhost:5900/users/auth/att/callback')
  })

  get "/" do
    erb "<div class='well'><a href='#{ATT.authorize_url('webrtc,profile,messages,geo,locker,addressbook')}' class='btn btn-primary'>Login</a></div>", :layout=>:layout
  end

  get "/phone" do
    erb :phone
  end

  get '/authorize' do
     auth_url = ATT.authorize_url('webrtc')
     "<hr><a href='#{auth_url}'>#{auth_url}</a><hr>"
  end

  # Receive the oauth callback, and exchange the code for an access token
  get '/users/auth/att/callback' do
    if params[:code]
      access_token = ATT.exchnage_code_for_access_token(params[:code])
      response.set_cookie('access_token', access_token )
      "access_token = #{access_token}"
    else
      raise 400, "#{params[:error]} : #{params[:error_reason]}"
    end
  end


  #Generic 404 event handler... instead of sending HTML page
  not_found do
  	'This is nowhere to be found.'
  end
  # error 500 do
  #   'You made me bleed 500 sucker'
  # end
  # error do
  #   'You aint my friend, Palooka. '
  # end
  
end