require 'rubygems'
require 'httparty'
require 'uri'
require 'yajl/json_gem'

class Att
   include HTTParty
   base_uri(ENV['ATT_BASE_DOMAIN'] || "https://api.tfoundry.com/a1/oauth")
   #base_uri("https://auth.tfoundry.com")
   headers('Content-Type'=>'application/json', 'Accept'=>'application/json')  #TODO: including these headers should not break things.  These headers are needed for BF api calls.
   debug_output
   format :json

   attr_accessor :access_token, :misdn
   
   def initialize(opts={})
     opts.each{|k,v| instance_variable_set("@#{k}".to_sym, v) }
   end
   
   def escape(str)
     URI.escape(str, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
   end

   # Generate the url to initiate an autorization request for a given scope
   def authorize_url(scope='profile') 
     "#{Att.base_uri}/oauth/authorize?scope=#{escape(scope)}&client_id=#{@client_id}&response_type=code&redirect_uri=#{escape(@redirect_uri)}"
   end

   # Exchange the request code for an access_token
   def exchnage_code_for_access_token(code)
      query = { :client_id      => @client_id, 
                :client_secret  => @client_secret,
                :redirect_uri   => @redirect_uri,
                :code           => code,
                :grant_type     => 'authorization_code'
                }
    query_string = "client_id=#{query[:client_id]}&client_secret=#{query[:secret]}&redirect_uri=#{query[:redirect_uri]}k&grant_type=#{query[:grant_type]}&code=#{query[:code]}"
       @access_token = Att.post("/oauth/token?#{query_string}")
      # @access_token = Att.post("/oauth/token", query)

      puts @access_token.inspect
      @access_token.parsed_response
   end
   
   # ============
   # = Location =
   # ============
   def location(tel=@misdn, accuracy=1000)
     raise "You must have an requested an access_token before requesting location" unless access_token
     ATT.get("/devices/tel:#{tel}/location", :query=>{:access_token=>access_token, :requestedAccuracy=>accuracy})
   end
    
end