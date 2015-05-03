require "delegate"
require "forwardable"
require "rack"
require "http_router"
require "tnt"
require "json"

module Barcelona
  class Request < DelegateClass(Rack::Request)
    def initialize(env = { })
      super Rack::Request.new(env)
      yield self if block_given?
    end

    def args
      env.fetch 'router.params', { }
    end

    def data
      case content_type
      when /application\/json/
        JSON.load(body).tap do |json|
          body.rewind
        end
      else
        params
      end
    end
  end

  class Response < DelegateClass(Rack::Response)
    RESPONSE_CODES = [
      [ 200, :ok ],
      [ 201, :created ],
      [ 202, :queued ],
      [ 204, :no_content ],
      [ 400, :bad_request ],
      [ 401, :unauthorized ],
      [ 402, :payment_required ],
      [ 403, :forbidden ],
      [ 404, :not_found ],
      [ 405, :unsupported_method ],
      [ 422, :unprocessable_entity ]
    ]

    RESPONSE_CODES.each do |status|
      code, name = status

      define_singleton_method name do |&block|
        new do |response|
          response.status = code
          block.call response if block
        end
      end
    end

    def initialize
      super Rack::Response.new
      yield self if block_given?
    end

    def body=(data)
      super [ data.to_s ]
    end

    def content_type=(value)
      self.headers['Content-Type'] = value
    end

    def json=(object)
      self.body = JSON.dump object
      self.content_type = 'application/json'
    end

    def html=(text)
      self.body = text
      self.content_type = 'text/html'
    end
  end

  class Dispatcher
    def initialize(processor)
      @processor = processor
    end

    def implemented?(action)
      processor.respond_to? action
    end

    def dispatch(action, env)
      processor.send(action, Request.new(env)).finish
    end

    def not_found(env)
      if implemented? :not_found
        dispatch :not_found, env
      else
        Response.not_found
      end
    end

    private

    def processor
      @processor
    end
  end

  MappingError = Tnt.boom do |action|
    "Cannot map to undefined method #{action}"
  end

  class Mapper
    extend Forwardable

    HTTP_METHODS = [
      :get,
      :post,
      :put,
      :delete,
      :patch,
      :options,
      :head,
      :link,
      :unlink
    ]

    def_delegators :router, :call

    def initialize(processor)
      @dispatcher = Dispatcher.new processor

      @router = HttpRouter.new.tap do |http|
        http.default_app = proc do |env|
          dispatcher.not_found env
        end
      end

      yield self if block_given?
    end

    HTTP_METHODS.each do |http_method|
      define_method http_method do |path, name|
        if dispatcher.implemented? name
          router.send(http_method, path).to do |env|
            dispatcher.dispatch(name, env)
          end
        else
          fail MappingError, name
        end
      end
    end

    def static(path, directory)
      router.add(path).static(directory)
    end

    private

    def router
      @router
    end

    def dispatcher
      @dispatcher
    end
  end
end
