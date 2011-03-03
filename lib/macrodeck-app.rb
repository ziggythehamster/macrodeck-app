# The core of the MacroDeck application.
# Need a way to handle extensions and allow extending this base app with more stuff.

require 'sinatra/base'
require 'active_support' # For the inflector.
require 'erb'

module MacroDeck
	class App < Sinatra::Base
		attr_accessor :configuration

		def initialize(app, configuration)
			self.configuration = configuration
			set :views, File.join(File.dirname(__FILE__), "..", self.configuration.view_dir.to_s)
			super(app)
		end

		helpers do
			include Rack::Utils
			alias_method :h, :escape_html

			# If there ends up being a lot of these helpers, I need to move them to MacroDeck::AppHelpers or something.

			# Returns either nil, or the platform object requested (unless it's not a platform object)
			# So basically get_platform_object("places").get("ID") or whatever.
			def get_platform_object(str)
				# Attempt a lookup like places (or place) => Place
				begin
					obj = str.pluralize.classify.constantize
					if obj.superclass == ::DataObject
						return obj
					else
						return nil
					end
				rescue NameError
					# Other situations (can't think of any) go here
					return nil
				end
			end
		end

		set :public, File.join(File.dirname(__FILE__), "..", "public")

		get '/' do
			@data_objects = DataObjectDefinition.all
			erb :home, :layout => self.configuration.layout.to_sym
		end

		# Index (odd count of splats)
		get '/*' do
			splat = params[:splat][0].split("/")
			if splat.length % 2 > 0
				@object = get_platform_object(splat[-1])

				if !@object.nil?
					# FIXME: Probably a bad idea to load ALL objects, right? :)
					@objects = @object.all
					erb :index, :layout => self.configuration.layout.to_sym, :locals => { :objects => @objects }
				else
					not_found
				end
			else
				pass # To the show function.
			end
		end

		# Show (even count of splats)
		get '/*' do
			splat = params[:splat][0].split("/")
			if splat.length % 2 == 0
				@object = get_platform_object(splat[-2])

				if !@object.nil?
					@item = @object.get(splat[-1])

					if !@item.nil?
						erb :show, :layout => self.configuration.layout.to_sym, :locals => { :item => @item }
					else
						not_found
					end
				end
			end
		end
	end
end
