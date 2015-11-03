require 'dotenv'
require "announcer/version"
require "announcer/runner"

Dotenv.load(".env")

module Announcer
  class << self
   attr_accessor :configuration
 end

 def self.configure
   self.configuration ||= Announcer::Configuration.new
 end

 class Configuration
   attr_accessor :github_access_token
   attr_accessor :jenkins_url
   attr_accessor :github_username

   def initialize
     @jenkins_url = ENV.fetch('JENKINS_URL')
     @github_username = ENV.fetch('GITHUB_USERNAME')
     @github_access_token = ENV.fetch('GITHUB_ACCESS_TOKEN')
   end
 end
end
