# The core of the MacroDeck application.
# Need a way to handle extensions and allow extending this base app with more stuff.

require 'sinatra/base'
require 'active_support' # For the inflector.
require 'erb'

module MacroDeck
	class App < Sinatra::Base
		attr_accessor :configuration
		use Rack::MethodOverride # Allow browsers to use a RESTful API

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

			# Returns a path to +item+
			def item_path(item)
				klass = item.class.to_s.underscore.pluralize
				return "/#{klass}/#{item.id}"
			end

			# Returns a path to the object from the +obj+ passed in.
			def items_path(obj)
				klass = obj.to_s.underscore.pluralize
				return "/#{klass}"
			end
		end

		set :public, File.join(File.dirname(__FILE__), "..", "public")

		get '/' do
			@data_objects = DataObjectDefinition.all
			erb :home, :layout => self.configuration.layout.to_sym
		end

		# Edit data type (odd count of splats)
		get '/*/edit/?' do
			splat = params[:splat][0].split("/")
			pass unless splat.length % 2 > 0

			# edit data type
			not_found
		end

		# Create a new data item (odd count of splats)
		post '/*' do
			splat = params[:splat][0].split("/")
			pass unless splat.length % 2 > 0

			@object = get_platform_object(splat[-1])

			if !@object.nil?
				@item = @object.new

				@object.properties.each do |f|
					@item[f.name.to_sym] = params[f.name.to_sym] unless params[f.name.to_sym].nil?
				end

				@item.created_by = "_system/MacroDeckApp"

				if @item.save
					redirect item_path(@item)
				else
					erb :"new.html", :layout => self.configuration.layout.to_sym, :locals => { :item => @item, :object => @object }
				end
			end
		end

		# Render the interface for creating a new data item (odd count of splats)
		get '/*/new/?' do
			splat = params[:splat][0].split("/")
			pass unless splat.length % 2 > 0
			@object = get_platform_object(splat[-1])

			if !@object.nil?
				@item = @object.new

				erb :"new.html", :layout => self.configuration.layout.to_sym, :locals => { :item => @item, :object => @object }
			end
		end

		# Edit data item (even count of splats)
		get '/*/edit/?' do
			splat = params[:splat][0].split("/")
			pass unless splat.length % 2 == 0
			@object = get_platform_object(splat[-2])

			if !@object.nil?
				@item = @object.get(splat[-1])

				if !@item.nil?
					erb :"edit.html", :layout => self.configuration.layout.to_sym, :locals => { :item => @item, :object => @object }
				end
			end
		end

		# Update data item (even count of splats)
		put '/*' do
			splat = params[:splat][0].split("/")
			pass unless splat.length % 2 == 0
			@object = get_platform_object(splat[-2])
			if !@object.nil?
				@item = @object.get(splat[-1])
				@object.properties.each do |f|
					unless params[f.name.to_sym].nil?
						if @item[f.name.to_sym] == ""
							@item[f.name.to_sym] = nil
						else
							@item[f.name.to_sym] = params[f.name.to_sym]
						end
					end
				end

				# Set update properties, except the user isn't yet known.
				@item.updated_by = "_system/MacroDeckApp"

				if @item.save
					redirect item_path(@item)
				else
					erb :"edit.html", :layout => self.configuration.layout.to_sym, :locals => { :item => @item, :object => @object }
				end
			end
		end

		# Index (odd count of splats)
		get '/*' do
			splat = params[:splat][0].split("/")
			if splat.length % 2 > 0
				@object = get_platform_object(splat[-1])

				if !@object.nil?
					# FIXME: Probably a bad idea to load ALL objects, right? :)
					@objects = @object.all
					erb :index, :layout => self.configuration.layout.to_sym, :locals => { :object => @object, :objects => @objects }
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
						# Get children
						grouplevel = @item.path.dup.length + 1
						startkey = @item.path.dup.push(0)
						endkey = @item.path.dup.push({})
						children_ids = []
						result = ::DataObject.view("by_path_alpha", :reduce => true, :group => true, :group_level => grouplevel, :startkey => startkey, :endkey => endkey)
						if result["rows"]
							result["rows"].each do |r|
								if r["key"][-1].include?("/")
									children_ids << r["key"][-1].split("/")[1]
								end
							end
						end
						if children_ids.length > 0
							docs = ::DataObject.database.get_bulk(children_ids)
							if docs["rows"]
								@children = docs["rows"].collect { |d| ::DataObject.create_from_database(d["doc"]) }
							end
						else
							@children = nil
						end

						erb :show, :layout => self.configuration.layout.to_sym, :locals => { :item => @item }
					else
						not_found
					end
				end
			end
		end
	end
end
