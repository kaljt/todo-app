require 'sinatra'
require 'sinatra/reloader' if development?
require 'sinatra/content_for'
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
end

helpers do
  def list_complete?(todos_list)
    todos_count(todos_list) > 0 && todos_remaining_count(todos_list) == 0
  end
  
  def list_class(list)
    "complete" if list_complete?(list)
  end
  
  def todos_count(list)
    list[:todos].size
  end
  
  def todos_remaining_count(list)
    list[:todos].select { |todo| !todo[:completed] }.size
  end
  
  def sort_lists(lists, &block)

    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }
    
    incomplete_lists.each { |list| yield list, lists.index(list) }
    complete_lists.each { |list| yield list, lists.index(list) }
  end
  
  def sort_todos(todos, &block)
    
    complete_todos, incomplete_todos = todos.partition { |todo| todo[:completed] }
    incomplete_todos.each { |todo| yield todo, todos.index(todo) }
    complete_todos.each { |todo| yield todo, todos.index(todo) }
   #incomplete_todos = {}
   #complete_todos = {}
   #
   #todos.each_with_index do |todo, index|
   #  if todo[:completed]
   #    complete_todos[todo] = index
   #  else
   #    incomplete_todos[todo] = index
   #  end
   #end
    #incomplete_todos.each(&block)
    #complete_todos.each(&block)
  end
  
  def error_for_list_name(name)
    if !(1..100).cover? name.size
      'List name must be between 1 and 100 characters'
    elsif session[:lists].any? { |list| list.value?(name) }
      'List name must be unique'
    end
  end
  
  def error_for_todo(name)
    if !(1..100).cover? name.size
      'List name must be between 1 and 100 characters'
    end
  end
end

get '/' do
  redirect '/lists'
end

# View list of lists
get '/lists' do
  @lists = session[:lists]
  erb :lists, layout: :layout
end
# Render the new list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

# Create a new list
post '/lists' do
  list_name = params[:list_name].strip

  if error = error_for_list_name(list_name)
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:id' do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  erb :list, layout: :layout
end

post '/lists/:id' do
  list_name = params[:list_name].strip

  if error = error_for_list_name(list_name)
    @list = session[:lists][params[:id].to_i]
    session[:error] = error
    erb :edit_list, layout: :layout
  else
    session[:lists][params[:id].to_i].store(:name, list_name)
    session[:success] = 'The list has been renamed.'
    redirect "/lists/#{params[:id]}"
  end 
end

get '/lists/:id/edit' do
  @list = session[:lists][params[:id].to_i]
  erb :edit_list, layout: :layout
end
# Delete a todo list
post '/lists/:id/destroy' do
  id = params[:id].to_i
  session[:lists].delete_at(id)
  session[:success] = "The list has been deleted"
  redirect '/lists'
end

# Add a new todo to an existing list
post "/lists/:list_id/todos" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  text = params[:todo].strip
  
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list, layout: :layout
  else
  @list[:todos] << {name: params[:todo], completed: false}
  session[:success] = "todo item added to list"
  redirect "/lists/#{@list_id}"
  end
  
end

post "/lists/:list_id/todos/:id/destroy" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  @list[:todos].delete_at(todo_id)
  session[:success] = "The todo has been deleted."
  redirect "/lists/#{@list_id}"

end

# Update status of a todo to complete or not

post "/lists/:list_id/todos/:id" do
  @list_id = params[:list_id].to_i
  @list = session[:lists][@list_id]
  
  todo_id = params[:id].to_i
  is_completed = params[:completed] == "true"
  @list[:todos][todo_id][:completed] = is_completed
  session[:success] = "The todo has been updated."
  redirect "/lists/#{@list_id}"
  
end

# Mark all todos as complete

post "/lists/:id/complete_all" do
  @list_id = params[:id].to_i
  @list = session[:lists][@list_id]
  
  @list[:todos].each do |todo|
    todo[:completed] = true
  end
  
  session[:success] = "All todos have been completed."
  redirect "/lists/#{@list_id}"
end
