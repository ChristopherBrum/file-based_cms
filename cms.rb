# frozen_string_literal: true
require 'yaml'
require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'secret_session_id'
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test/data', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def load_users_credentials
  credentials_path = if ENV["RACK_ENV"] == "test"
    File.expand_path('../test/users.yml', __FILE__)
  else
    File.expand_path('../users.yml', __FILE__)
  end
  YAML.load_file(credentials_path)
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when '.txt'
    headers['Content-Type'] = 'text/plain'
    content
  when '.md'
    erb render_markdown(content)
  end
end

def require_signed_in_user
  unless user_logged_in?
    session[:message] = "You must be signed in to do that."
    redirect '/'
  end
end

def user_logged_in?
  session[:logged_in]
end

# index page lists all files
get '/' do
  pattern = File.join(data_path, '*')
  @files = Dir.glob(pattern)
              .map { |path| File.basename(path) }

  erb :index
end

# Display form for adding a new file
get '/new' do
  require_signed_in_user

  erb :new
end

# creates a new file
post '/create' do
  require_signed_in_user

  filename = params[:filename].to_s

  if filename.size.zero?
    session[:message] = 'A name is required'
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, '')
    session[:message] = "#{params[:filename]} has been created."

    redirect '/'
  end
end

# display the sign in page
get "/users/login" do
  erb :login
end

def valid_credentials?(username, password)
  credentials = load_users_credentials

  if credentials.key?(username)
    bcrypt_password = BCrypt::Password.new(credentials[username])
    bcrypt_password == params[:password]
  else
    false
  end
end

# signs the user in
post '/users/login' do
  username = params[:username]
  password = params[:password]
  
  if valid_credentials?(username, password)
    session[:logged_in] = true
    session[:username] = username
    session[:message] = 'Welcome!'
    redirect '/'
  else
    session[:message] = 'Invalid Credentials.'
    erb :login
  end
end

# Signs out the user
post '/users/logout' do
  session[:logged_in] = false
  session[:username] = nil
  session[:message] = 'You have been signed out.'
  redirect '/'
end

# displays selected file
get '/:filename' do
  file_path = File.join(data_path, params[:filename])
  file_name = params[:filename]

  if File.exist?(file_path)
    load_file_content(file_path)
  else
    session[:message] = "#{file_name} does not exist."
    redirect '/'
  end
end

# display the edit page for a file
get '/:filename/edit' do
  require_signed_in_user

  file_path = File.join(data_path, params[:filename])
  @file_name = params[:filename]
  @file_contents = File.read(file_path)

  erb :edit
end

# Update the selected file
post '/:filename' do
  require_signed_in_user

  file_name = params[:filename]
  file_path = File.join(data_path, file_name)

  File.write(file_path, params[:content])

  session[:message] = "#{file_name} has been updated."
  redirect '/'
end

# Deletes a file
post '/:filename/delete' do
  require_signed_in_user

  file_name = params[:filename]
  file_path = File.join(data_path, file_name)

  File.delete(file_path)

  session[:message] = "#{file_name} has been deleted."
  redirect '/'
end
