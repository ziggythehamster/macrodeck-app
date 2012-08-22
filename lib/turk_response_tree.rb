module MacroDeck
	module TurkResponseTree
		# This error is raised if a path is requested which doesn't
		# exist.
		class InvalidPathError < StandardError; end

		# A TurkResponseTree::Tree is a hash of hashes that contains the
		# verified answers from a Turk. The hash can be accessed
		# using a URL-like path or by traversing the tree.
		class Tree
			# Pass in the item in order to be able to access the
			# response tree.
			def initialize(item)
				raise "Passed item cannot be nil" if item.nil?

				@item = item
				if @item.turk_responses.nil?
					@hash = MacroDeck::PathableHash.new # Turk responses can initialize to nil
				else
					@hash = MacroDeck::PathableHash[item.turk_responses]
				end

				@paths = {} # To expedite lookup
				@values_at_paths = {} # To expedite lookup
				@all_paths = []
			end

			def [](key)
				@hash[key]
			end

			# Returns a list of all paths
			def all_paths
				return @all_paths if @all_paths.length > 0

				# Looks like we have to build a list of paths!
				puts "[MacroDeck::TurkResponseTree::Tree] Getting all paths..."
				@hash.each_path do |path, value|
					if !@all_paths.include?(path)
						puts "[MacroDeck::TurkResponseTree::Tree] Adding path #{path}"
						@all_paths << path
					end
				end
			end

			# Returns the tree at the path requested.
			# Raises InvalidPathError if the path doesn't exist.
			def at_path(path)
				raise "Path cannot be nil." if path.nil?

				if path =~ %r{^/}
					normalized_path = path
				else
					normalized_path = "/#{path}"
				end

				return @paths[normalized_path] if @paths.key?(normalized_path)

				# Looks like we have to look this up.
				path_components = normalized_path.split("/")[1..-1]

				root = @hash

				raise "Path components are nil somehow. Normalized path=#{normalized_path} Path=#{path}" if path_components.nil?

				path_components.each do |p|
					if p.include?("=")
						if root.key?(p)
							root = root[p]
						else
							raise InvalidPathError, "#{p} not found"
						end
					else
						if root.key?("#{p}=")
							root = root["#{p}="]
						else
							raise InvalidPathError, "#{p}= not found"
						end
					end
				end

				# root at this point is what we will return.
				@paths[normalized_path] = root
				return @paths[normalized_path]
			end

			# Similar to +at_path+, except that it returns the value at the path
			# requested, and can't be used to further traverse the tree.
			def value_at_path(path)
				if path =~ %r{^/}
					normalized_path = path
				else
					normalized_path = "/#{path}"
				end

				puts "[MacroDeck::TurkResponseTree::Tree] Getting value at path: #{normalized_path}"

				return @values_at_paths[normalized_path] if @values_at_paths.key?(normalized_path)

				# Look up!
				path_components = normalized_path.split("/")[1..-1]

				root = @hash
				val = nil
				path_components.each do |p|
					puts "[MacroDeck::TurkResponseTree::Tree] Processing path component: #{p}"

					# See if this is the last path component (we need the value)
					if p == path_components.last
						puts "[MacroDeck::TurkResponseTree::Tree] Last path component - getting value"

						if p.include?("=")
							if !root.nil? && root.key?(p.split("=")[0])
								root = root[p.split("=")[0]]
							else
								raise InvalidPathError, "#{p.split("=")[0]} not found"
							end
						else
							if !root.nil? && root.key?(p)
								root = root[p]
							else
								raise InvalidPathError, "#{p} not found"
							end
						end
					else
						puts "[MacroDeck::TurkResponseTree::Tree] Not last path component - traversing tree"

						if p.include?("=")
							if root.key?(p)
								root = root[p]
							else
								raise InvalidPathError, "#{p} not found"
							end
						else
							if root.key?("#{p}=")
								root = root["#{p}="]
							else
								raise InvalidPathError, "#{p}= not found"
							end
						end
					end
				end

				@values_at_paths[normalized_path] = root
				return @values_at_paths[normalized_path]
			end
		end
	end
end
