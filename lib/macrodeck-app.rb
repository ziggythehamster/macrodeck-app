# The core of the MacroDeck application.
# Need a way to handle extensions and allow extending this base app with more stuff.

require 'sinatra/base'
require 'active_support' # For the inflector.
require 'erb'

module MacroDeck
	class App < Sinatra::Base
		helpers do
			include Rack::Utils
			alias_method :h, :escape_html

			# If there ends up being a lot of these helpers, I need to move them to MacroDeck::AppHelpers or something.

			# Returns either nil, or the platform object requested.
			# So basically get_platform_object("places").get("ID") or whatever.
			def get_platform_object(str)
				# Attempt a lookup like places (or place) => Place
				begin
					return str.pluralize.classify.constantize
				rescue NameError
					# Other situations (can't think of any) go here
					return nil
				end
			end
		end

		set :public, File.join(File.dirname(__FILE__), "..", "public")

		get '/' do
			@data_objects = DataObjectDefinition.all
			erb :home, :layout => MD_CFG.layout.to_sym
		end

		get '/:object_type/?' do
			if get_platform_object(params[:object_type])
				# FIXME: Probably a bad idea to load ALL objects, right? :)
				erb :index, :layout => MD_CFG.layout.to_sym, :locals => { :objects => get_platform_object(params[:object_type]).all }
			else
				not_found
			end
		end

		get '/:object_type/:id/?' do
			#TODO: Requesting a specific ID
		end


	end
end
