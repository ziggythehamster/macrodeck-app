module MacroDeck
	module TurkResponseTree
		# This error is raised if a path is requested which doesn't
		# exist.
		class InvalidPathError < StandardError; end

		# A TurkResponseTree::Tree is a hash of hashes that contains the
		# verified answers from a Turk. The hash can be accessed
		# using a URL-like path or by traversing the tree.
		class Tree
			# Pass in the response hash in order to be able to access the
			# response tree.
			def initialize(hash)
				@hash = hash
				@hash ||= {} # Turk responses can initialize to nil
				@paths = {} # To expedite lookup
				@values_at_paths = {} # To expedite lookup
			end

			def [](key)
				@hash[key]
			end

			# Returns the tree at the path requested.
			# Raises InvalidPathError if the path doesn't exist.
			def at_path(path)
				return @paths[path] if @paths.key?(path)

				# Looks like we have to look this up.
				if path =~ %r{^/}
					path_components = path.split("/")[1..-1]
				else
					path_components = path.split("/")
				end

				root = @hash
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
				@paths[path] = root
				return @paths[path]
			end

			# Similar to +at_path+, except that it returns the value at the path
			# requested, and can't be used to further traverse the tree.
			def value_at_path(path)
				return @values_at_paths[path] if @values_at_paths.key?(path)

				# Look up!
				if path =~ %r{^/}
					path_components = path.split("/")[1..-1]
				else
					path_components = path.split("/")
				end

				root = @hash
				val = nil
				path_components.each do |p|
					# See if this is the last path component (we need the value)
					if p == path_components.last
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

					@values_at_paths[path] = root
					return @values_at_paths[path]
				end

			end
		end
	end
end
