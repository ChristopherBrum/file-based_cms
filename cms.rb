require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret_session_id'
end

def data_path
  if ENV["RACK_ENV"] == "test"
    File.expand_path("../test/data/", __FILE__)
  else
    File.expand_path("../data/", __FILE__)
  end
end

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    content
  when ".md"
    erb render_markdown(content)
  end
end

# index page lists all files
get "/" do
  pattern = File.join(data_path, "*")
  @files = Dir.glob(pattern).map { |path| File.basename(path) }

  erb :index
end

# Display form for adding a new file
get "/new" do
  erb :new
end

# creates a new file
post "/create" do
  filename = params[:filename].to_s

  if filename.size == 0
    session[:message] = "A name is required"
    status 422
    erb :new
  else
    file_path = File.join(data_path, filename)

    File.write(file_path, "")

    session[:message] = "#{params[:filename]} was created."
    redirect "/"
  end
end

# displays selected file
get "/:filename" do
  file_path = File.join(data_path, params[:filename])
  @file_name = params[:filename]

  if File.exist?(file_path) 
    load_file_content(file_path)
  else
    session[:message] = "#{@file_name} does not exist."
    redirect "/"
  end
end

# display the edit page for a file
get "/:filename/edit" do 
  file_path = File.join(data_path, params[:filename])

  @file_name = params[:filename]
  @file_contents = File.read(file_path)

  erb :edit
end

# Update the selected file
post "/:filename" do
  file_name = params[:filename]
  file_path = File.join(data_path, file_name)

  File.write(file_path, params[:content])

  session[:message] = "#{file_name} has been updated."
  redirect "/"
end

# Deletes a file
post "/:filename/delete" do
  file_name = params[:filename]
  file_path = File.join(data_path, file_name)

  File.delete(file_name)

  session[:message] = "#{file_name} has been deleted."
  redirect "/"
end
