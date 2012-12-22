$stdout.sync = true
$:.unshift(File.dirname(__FILE__))
require File.dirname(__FILE__)+'/app.rb'

run WebrtcPhone


