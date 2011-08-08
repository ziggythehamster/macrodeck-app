# The core of the MacroDeck application.
# Need a way to handle extensions and allow extending this base app with more stuff.

# Gems used by this lib.
gem "activesupport"
gem "uuidtools"

# Things to require.
require 'sinatra/base'
require 'active_support' # For the inflector.
require 'uuidtools'
require 'erb'

module MacroDeck
	class Turk < Sinatra::Base
		cattr_accessor :configuration

		use Rack::MethodOverride # Allow browsers to use a RESTful API

		helpers do
			include Rack::Utils
			alias_method :h, :escape_html
		end


		# Render a question for the requested ID.
		get '/:id' do

		end
	end
end
