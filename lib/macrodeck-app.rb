require 'sinatra/base'
require 'erb'

module MacroDeck
	class App < Sinatra::Base
		helpers do
			include Rack::Utils
			alias_method :h, :escape_html
		end

		set :public, File.join(File.dirname(__FILE__), "..", "public")

		get '/' do
			@data_objects = DataObjectDefinition.all
			erb :index
		end
	end
end
