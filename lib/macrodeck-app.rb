require 'sinatra/base'

module MacroDeck
	class App < Sinatra::Base
		get '/' do
			'Test'
		end
	end
end
