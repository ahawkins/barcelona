# Barcelona

Barcelona is a simple HTTP to object mapper. HTTP methods & path names
are assigned to methods on a processor object. Each processor method
accepts one argument (`Barcelona::Request`) and returns a response
`(Barcelona::Response)`. Barcelona creates [rack][] compatible objects so
any standard web server will work. In short, it exposes objects to the
internet via HTTP.

[http\_router][] & [rack][] power the internals.

## Why?

Mapping HTTP Verb & Path to a method is all you need. This approach is
simple and object oriented. It also eliminates as much state as
possible leaving request/response processing as functional as
possible. It get out of your way to so you can generate a response in
which ever way you like.

## Installation

Add this line to your application's Gemfile:

	gem 'barcelona'

And then execute:

	$ bundle

Or install it yourself as:

	$ gem install barcelona

## Usage

Define a processor class that implements all required methods.

	class Processor
		def create_user(request)
			Barcelona::Response.ok do |response|
				response.json = { nick: 'ahawkins' }
			end
		end
	end

Now map HTTP track to methods.

	app = Barcelona::Mapper.new Processor.new do |http|
		http.post '/users', :create_user
	end

`app` responds to `call` so it can be used in `config.ru` via:

	run app

## Development

	$ make test

## Contributing

1. Fork it ( https://github.com/[ahawkins]/barcelona/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
