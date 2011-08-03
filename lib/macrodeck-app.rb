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
	class App < Sinatra::Base
		cattr_accessor :configuration

		use Rack::MethodOverride # Allow browsers to use a RESTful API

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

			# Returns an array of the path from the specified URL fragment.
			def url_path_to_item_path(path)
				path_tok = path.split("/")

				item_path = []
				path_tok.each_index do |idx|
					item_path << path_tok[idx] if idx % 2 > 0
				end

				return item_path
			end

			# Returns a path to +item+, using its expanded path info.
			def item_path(item)
				path = self.configuration.path_prefix.to_s.dup
				exp_path = item.expanded_path

				exp_path.each do |p|
					path << "#{p[0].underscore.pluralize}/#{p[1]}/"
				end

				return path
			end

			# Returns a path to the object from the +obj+ passed in.
			def items_path(obj, parent_item = nil)
				if parent_item
					path = self.configuration.path_prefix.to_s.dup
					exp_path = parent_item.expanded_path

					exp_path.each do |p|
						path << "#{p[0].underscore.pluralize}/#{p[1]}/"
					end

					path << obj.to_s.underscore.pluralize
					return path
				else
					klass = obj.to_s.underscore.pluralize
					return "#{self.configuration.path_prefix.to_s.dup}#{klass}"
				end
			end

			# Populates @item_path from the item path (see url_path_to_item_path)
			def get_item_path(ids)
				docs = ::DataObject.database.get_bulk(ids)
				if docs["rows"]
					@item_path = docs["rows"].collect { |d| ::DataObject.create_from_database(d["doc"]) }
				else
					@item_path = nil
				end
			end

			# Updates item with params.
			def update_item_properties(item, params)
				item.class.properties.each do |f|
					unless params[f.name.to_sym].nil?
						# Simple types can just be set, but more complicated things
						# will use the behavior system to parse them.
						if params[f.name.to_sym].is_a?(Hash)
							behavior_class = "#{f.to_s}_behavior".camelize
							behavior_class = "MacroDeck::#{behavior_class}"

							begin
								behavior = behavior_class.constantize
							rescue NameError
								behavior = nil
							end

							if !behavior.nil? && !(item.class.introspections[f.to_sym][:internal] == true) && behavior.respond_to?(:parse_result)
								item[f.name.to_sym] = behavior.parse_result(params[f.name.to_sym])
							else
								if params[f.name.to_sym] == ""
									item[f.name.to_sym] = nil
								else
									item[f.name.to_sym] = params[f.name.to_sym]
								end
							end
						else
							if params[f.name.to_sym] == ""
								item[f.name.to_sym] = nil
							else
								item[f.name.to_sym] = params[f.name.to_sym]
							end
						end
					end
				end
				return item
			end
		end

		get '/' do
			@data_objects = DataObjectDefinition.all
			@root_items = []
			reduce_root = ::DataObject.view("by_path_alpha", :include_docs => false, :reduce => true, :group => true, :group_level => 1)
			root_ids = []
			if reduce_root["rows"]
				reduce_root["rows"].each do |r|
					if r["key"][0].include?("/")
						root_ids << r["key"][0].split("/")[1]
					end
				end

				docs = ::DataObject.database.get_bulk(root_ids)
				@root_items = docs["rows"].collect { |d| ::DataObject.create_from_database(d["doc"]) } if docs["rows"]
			end

			erb :"home.html", :layout => self.configuration.layout.to_sym
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
				update_item_properties(@item, params)
				@item.created_by = "_system/MacroDeckApp"
				@item.updated_by = "_system/MacroDeckApp"
				@item.owned_by = "_system"
				@item.id = UUIDTools::UUID.random_create.to_s
				@item.path = url_path_to_item_path(params[:splat][0]) << @item.id

				if @item.path.length < 2
					@parent = nil
				else
					@parent = ::DataObject.get(@item.path[-2])
				end


				if @item.valid? && @item.save
					redirect item_path(@item)
				else
					erb :"new.html", :layout => self.configuration.layout.to_sym, :locals => { :item => @item, :object => @object, :parent => @parent }
				end
			end
		end

		# Render the interface for creating a new data item (odd count of splats)
		get '/*/new/?' do
			splat = params[:splat][0].split("/")
			pass unless splat.length % 2 > 0
			@object = get_platform_object(splat[-1])

			if !@object.nil?
				get_item_path(url_path_to_item_path(params[:splat][0]))

				@item = @object.new
				@item.id = UUIDTools::UUID.random_create.to_s
				@item.path = url_path_to_item_path(params[:splat][0]) << @item.id
				@item.created_by = "_system/MacroDeckApp"
				@item.updated_by = "_system/MacroDeckApp"
				@item.owned_by = "_system"
				if @item.path.length < 2
					@parent = nil
				else
					@parent = ::DataObject.get(@item.path[-2])
				end

				erb :"new.html", :layout => self.configuration.layout.to_sym, :locals => { :item => @item, :object => @object, :parent => @parent }
			end
		end

		# Edit data item (even count of splats)
		get '/*/edit/?' do
			splat = params[:splat][0].split("/")
			pass unless splat.length % 2 == 0
			@object = get_platform_object(splat[-2])

			if !@object.nil?
				@item = @object.get(splat[-1])
				get_item_path(url_path_to_item_path(params[:splat][0]))

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
				update_item_properties(@item, params)

				# Set update properties, except the user isn't yet known.
				@item.updated_by = "_system/MacroDeckApp"

				if @item.valid? && @item.save
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
					get_item_path(url_path_to_item_path(params[:splat][0]))

					path = url_path_to_item_path(params[:splat][0])
					startkey = path.dup.push(0)
					endkey = path.dup.push({})

					@objects = @object.view("by_path_alpha", :reduce => false, :startkey => startkey, :endkey => endkey)
					erb :"index.html", :layout => self.configuration.layout.to_sym, :locals => { :object => @object, :objects => @objects }
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
						get_item_path(url_path_to_item_path(params[:splat][0]))

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
						if !children_ids.nil? && children_ids.length > 0
							docs = ::DataObject.database.get_bulk(children_ids)
							if docs["rows"]
								@children = docs["rows"].collect do |d|
									if d["doc"]
										::DataObject.create_from_database(d["doc"])
									end
								end
								@children.compact!
							end
						else
							@children = nil
						end

						# Get a list of data object types.
						@data_objects = DataObjectDefinition.all

						erb :"show.html", :layout => self.configuration.layout.to_sym, :locals => { :item => @item }
					else
						not_found
					end
				end
			end
		end
	end
end
