require_relative 'test_helper'

class TestBarcelona < Minitest::Test
  include Rack::Test::Methods

  attr_reader :app

  def test_cannot_map_path_without_implementation
    ex = assert_raises Barcelona::MappingError do
      Barcelona::Mapper.new Object.new do |http|
        http.get '/foo', :foo_test
      end
    end

    assert_match /foo_test/, ex.message, 'Nondescript error message'
  end

  def test_maps_path_and_verb_to_appropriate_method
    processor = Class.new do
      define_method :foo_test do |request|
        Barcelona::Response.ok do |response|
          response.body = 'testing'
        end
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.get '/foo', :foo_test
    end

    get '/foo'

    assert_equal 200, last_response.status
    assert_equal 'testing', last_response.body
  end

  def test_unknown_routes_are_processed_as_not_found
    processor = Class.new do
      define_method :foo do |request|
        flunk 'Unreachable code'
      end

      define_method :not_found do |request|
        Barcelona::Response.ok do |response|
          response.body = 'not-found'
        end
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.get '/foo', :foo
    end

    get '/bar'

    assert_equal 200, last_response.status
    assert_equal 'not-found', last_response.body
  end

  def test_unkown_routes_return_404
    processor = Class.new do
      define_method :foo do |request|
        flunk 'Unreachable code'
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.get '/foo', :foo
    end

    get '/bar'

    assert_equal 404, last_response.status
  end

  def test_path_variables_passed_as_args
    processor = Class.new do
      define_method :foo_test do |request|
        Barcelona::Response.ok do |response|
          response.body = request.args.fetch :bar
        end
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.get '/foo/:bar', :foo_test
    end

    get '/foo/testing'

    assert_equal 200, last_response.status
    assert_equal 'testing', last_response.body
  end

  def test_can_assign_json_response
    processor = Class.new do
      define_method :foo_test do |request|
        Barcelona::Response.ok do |response|
          response.json = { foo: 'bar' }
        end
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.post '/foo', :foo_test
    end

    post '/foo'

    assert_equal 200, last_response.status
    assert_match /application\/json/, last_response.content_type, 'Incorrect content type'

    data = JSON.load last_response.body
    assert_equal 'bar', data.fetch('foo'), 'JSON body incorrect'
  end

  def test_union_of_post_and_query_params_accessible_in_data
    processor = Class.new do
      define_method :foo_test do |request|
        Barcelona::Response.ok do |response|
          response.json = request.data
        end
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.post '/foo', :foo_test
    end

    post '/foo?bar=baz', testing: :data

    assert_equal 200, last_response.status
    assert_match /application\/json/, last_response.content_type, 'Incorrect content type'

    data = JSON.load last_response.body
    assert_equal 'baz', data.fetch('bar'), 'Query param incorrect'
    assert_equal 'data', data.fetch('testing'), 'Form body param incorrect'
  end

  def test_json_encoded_bodies_accessible_in_data
    processor = Class.new do
      define_method :foo_test do |request|
        Barcelona::Response.ok do |response|
          response.body = request.data.fetch 'foo'
        end
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.post '/foo', :foo_test
    end

    post('/foo', JSON.dump({ foo: 'bar' }), { 'CONTENT_TYPE' => 'application/json' })

    assert_equal 200, last_response.status
    assert_equal 'bar', last_response.body, 'JSON handled incorrectly'
  end

  def test_html_response
    processor = Class.new do
      define_method :foo_test do |request|
        Barcelona::Response.ok do |response|
          response.html = '<foo>'
        end
      end
    end

    @app = Barcelona::Mapper.new processor.new do |http|
      http.get '/foo', :foo_test
    end

    get '/foo'

    assert_equal 200, last_response.status
    assert_match /text\/html/, last_response.content_type, 'Incorrect content type'
    assert_equal '<foo>', last_response.body
  end

  def test_serving_static_files
    Dir.mktmpdir do |scratch|
      File.open File.join(scratch, 'foo.txt'), 'w' do |foo|
        foo.write 'bar'
      end

      processor = Class.new

      @app = Barcelona::Mapper.new processor.new do |http|
        http.static '/public', scratch
      end

      get '/public/foo.txt'

      assert_equal 200, last_response.status
      assert_equal 'bar', last_response.body
    end
  end
end
