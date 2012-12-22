$stdout.sync = true
$:.unshift(File.dirname(__FILE__))
require File.dirname(__FILE__)+'/app.rb'

use Rack::Session::Cookie, :key => 'sinatra_phone',
                           :path => '/',
                           :expire_after => 14400, # In seconds
                           :secret => 'some-random-s3cr3t-string'

run WebrtcPhone

