ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "../cms.rb"

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_index
    get "/"

    assert_equal(200, last_response.status)
    assert_equal("text/html;charset=utf-8", last_response["Content-Type"])
    assert_includes(last_response.body, "changes.txt")
    assert_includes(last_response.body, "about.txt")
    assert_includes(last_response.body, "history.txt")

  end

  def test_filename
    get "/about.txt"
    
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "Maecenas mollis tincidunt euismod.")
  end
  
  def test_filename
    get "/changes.txt"
    
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "Nam augue quam")
  end

  def test_filename
    get "/history.txt"
    
    assert_equal(200, last_response.status)
    assert_equal("text/plain", last_response["Content-Type"])
    assert_includes(last_response.body, "2017 - Ruby 2.5 released.")
    assert_includes(last_response.body, "1993 - Yukihiro Matsumoto dreams up Ruby.")
  end

  def test_document_not_found
    get "/something.txt"

    assert_equal(302, last_response.status)

    get last_response["Location"]

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, "something.txt does not exist.")

    get "/"
    refute_includes(last_response.body, "something.txt does not exist.")
  end
end