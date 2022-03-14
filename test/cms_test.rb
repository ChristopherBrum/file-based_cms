# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'minitest/reporters'
Minitest::Reporters.use!
require 'fileutils'

require 'pry'

require_relative '../cms'

class CMSTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = '')
    File.open(File.join(data_path, name), 'w') do |file|
      file.write(content)
    end
  end

  def test_index
    create_document('about.md')
    create_document('changes.txt')
    create_document('history.txt')

    get '/'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, 'about.md')
    assert_includes(last_response.body, 'changes.txt')
    assert_includes(last_response.body, 'history.txt')
  end

  def test__markdown_file
    create_document('about.md', 'open source programming language')

    get '/about.md'

    assert_equal(200, last_response.status)
    assert_equal('text/html;charset=utf-8', last_response['Content-Type'])
    assert_includes(last_response.body, ' programming ')
  end

  def test_text_file
    create_document('changes.txt', 'Nam augue quam, feugiat id suscipit quis, vestibulum vitae magna.')

    get '/changes.txt'

    assert_equal(200, last_response.status)
    assert_equal('text/plain', last_response['Content-Type'])
    assert_includes(last_response.body, 'Nam augue quam')
  end

  def test_document_not_found
    get '/something.txt'

    assert_equal(302, last_response.status)

    get last_response['Location']

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'something.txt does not exist.')

    get '/'
    refute_includes(last_response.body, 'something.txt does not exist.')
  end

  def test_editing_document
    create_document('history.txt', '1993 - Yukihiro Matsumoto dreams up Ruby.')
    get '/history.txt/edit'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, '<textarea')
    assert_includes(last_response.body, '1993 - Yukihiro Matsumoto')
  end

  def test_updating_document
    create_document('changes.txt', 'Nam augue quam, feugiat id suscipit quis, ')

    get '/changes.txt'
    assert_includes(last_response.body, 'Nam augue quam,')

    post '/changes.txt', content: 'No longer contains changes'

    assert_equal(302, last_response.status)
    refute_includes(last_response.body, 'Nam augue quam,')
  end

  def test_view_new_document_form
    get '/new'

    assert_equal(200, last_response.status)
    assert_includes(last_response.body, 'new document')
    assert_includes(last_response.body, 'Create')
  end

  def test_create_new_document
    post '/create', filename: 'test.txt'
    assert_equal(302, last_response.status)

    get last_response['Location']
    assert_includes(last_response.body, 'test.txt was created')

    get '/'
    assert_includes(last_response.body, 'test.txt')
  end

  def test_create_new_document_without_filename
    post '/create', filename: ''
    assert_equal(422, last_response.status)
    assert_includes(last_response.body, 'A name is required')
  end

  def test_delete_document
    create_document('deletable.md', 'I hope this works!')

    post '/:filename/destroy'
    binding.pry
    assert_equal(302, last_response.status)

    get last_response['Location']
    assert_includes(last_response.body, 'deletable.md has been deleted')

    get '/'
    assert_equal(200, last_response.status)
    refute_includes(last_response.body, 'deletable.md')
  end
end
