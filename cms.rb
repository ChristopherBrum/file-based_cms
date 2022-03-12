require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'
require 'redcarpet'

configure do
  enable :sessions
  set :session_secret, 'secret_session_id'

  # use Rack::Session::Cookie, :key => 'rack.session',
  #                            :path => '/',
  #                            :secret => 'secret session id'
end

ROOT = File.expand_path("..", __FILE__) + "/data/"

def render_markdown(text)
  markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML)
  markdown.render(text)
end

def load_file_content(path)
  content = File.read(path)
  case File.extname(path)
  when ".txt"
    headers["Content-Type"] = "text/plain"
    File.read(path)
  when ".md"
    render_markdown(content)
  end
end

# index page lists all files
get "/" do
  @files = Dir.glob("#{ROOT}*")
              .map { |path| File.basename(path) }

  erb :index, layout: :layout
end

# displays selected file
get "/:filename" do
  file_path = ROOT + params[:filename]
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
  file_path = ROOT + params[:filename]
  @file_name = params[:filename]
  @file_contents = File.read(file_path)

  erb :edit
end

post "/:filename" do
  file_path = ROOT + params[:filename]
  @file_name = params[:filename]

  File.write(file_path, params[:content])
  session[:message] = "#{@file_name} has been updated."
  redirect "/"
end
