# Loads the config file for the current environment.

require "yaml"
require "sinatra"

module MacroDeck
	class Config
		attr_reader :environment
		attr_reader :layout
		attr_reader :view_dir
		attr_reader :path_prefix
		attr_reader :turk_path_prefix
		attr_reader :turk_sandbox
		attr_reader :turk_answer_hit_type_id
		attr_reader :turk_answer_reward
		attr_reader :turk_verify_hit_type_id
		attr_reader :turk_verify_reward
		attr_reader :aws_access_key
		attr_reader :aws_secret_access_key
		attr_reader :base_url

		def initialize(yaml_path)
			File.open(yaml_path) do |yml|
				@config = YAML::load(yml)
			end
			@environment = Sinatra::Application.environment.to_sym
			if @config[@environment.to_s]
				if @config[@environment.to_s]["layout"]
					@layout = @config[@environment.to_s]["layout"]
				else
					@layout = "layout"
				end

				if @config[@environment.to_s]["view_dir"]
					@view_dir = @config[@environment.to_s]["view_dir"]
				else
					@view_dir = "views"
				end

				if @config[@environment.to_s]["path_prefix"]
					@path_prefix = @config[@environment.to_s]["path_prefix"]
				else
					@path_prefix = "/"
				end

				if @config[@environment.to_s]["turk_path_prefix"]
					@turk_path_prefix = @config[@environment.to_s]["turk_path_prefix"]
				else
					@turk_path_prefix = "/turk/"
				end

				if @config[@environment.to_s]["turk_sandbox"]
					@turk_sandbox = @config[@environment.to_s]["turk_sandbox"]
				else
					@turk_sandbox = true
				end

				if @config[@environment.to_s]["turk_answer_hit_type_id"]
					@turk_answer_hit_type_id = @config[@environment.to_s]["turk_answer_hit_type_id"]
				else
					@turk_answer_hit_type_id = nil
				end

				if @config[@environment.to_s]["turk_answer_reward"]
					@turk_answer_reward = @config[@environment.to_s]["turk_answer_reward"]
				else
					@turk_answer_reward = 0.0
				end

				if @config[@environment.to_s]["turk_verify_hit_type_id"]
					@turk_verify_hit_type_id = @config[@environment.to_s]["turk_verify_hit_type_id"]
				else
					@turk_verify_hit_type_id = nil
				end

				if @config[@environment.to_s]["turk_verify_reward"]
					@turk_verify_reward = @config[@environment.to_s]["turk_verify_reward"]
				else
					@turk_verify_reward = 0.0
				end

				if @config[@environment.to_s]["aws_access_key"]
					@aws_access_key = @config[@environment.to_s]["aws_access_key"]
				else
					@aws_access_key = ""
				end

				if @config[@environment.to_s]["aws_secret_access_key"]
					@aws_secret_access_key = @config[@environment.to_s]["aws_secret_access_key"]
				else
					@aws_secret_access_key = ""
				end

				if @config[@environment.to_s]["base_url"]
					@base_url = @config[@environment.to_s]["base_url"].replace(/\/$/, "")
				else
					@base_url = "http://localhost:3000"
				end
			end

			# Configure RTurk if we have enough data
			if @aws_access_key != "" && @aws_secret_access_key != ""
				if @turk_sandbox
					RTurk.setup(@aws_access_key, @aws_secret_access_key, :sandbox => true)
				else
					RTurk.setup(@aws_access_key, @aws_secret_access_key, :sandbox => false)
				end
			end
		end
	end
end

# vim:set ft=ruby
