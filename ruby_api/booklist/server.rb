require 'sinatra'
require "sinatra/namespace"
require 'mongoid'


# DB Setup: load the Mongoid configuration
Mongoid.load! "mongoid.config"


# Create a Ruby class that includes Mongoid::Document to create our model.

class Book
  include Mongoid::Document


  # three fields for our books (isbn: International Standard Book Number - book identifier)
  field :title, type: String
  field :author, type: String
  field :isbn, type: String

  validates :title, presence: true
  validates :author, presence: true
  validates :isbn, presence: true

  index({ title: 'text' })
  index({ isbn:1 }, { unique: true, name: "isbn_index" })

  #  Scope is added to let the client filter the books via URL
  scope :title, -> (title) { where(title: /^#{title}/) }
  scope :isbn, -> (isbn) { where(isbn: isbn) }
  scope :author, -> (author) { where(author: author) }


end


# Serializers
class BookSerializer
  def initialize(book)
    @book = book
  end


  # Redines key values that will appear to the user when we call json
  def as_json(*)
    data = {
      id:@book.id.to_s,
      title:@book.title,
      author:@book.author,
      isbn:@book.isbn
    }
    data[:errors] = @book.errors if@book.errors.any?
    data
  end
end



# Endpoints

get '/' do
  'Welcome to BookList!'
end

# All the books endpoints (Index/Filtering, Show, Create, Update, Delete) are added inside this namespace block.
namespace '/api/v1' do

  # All we do in this code is get all the books, serialize them to JSON and return them.
  before do
    content_type 'application/json'
  end

# To add books to the DB from the browser, we need to be able to generate the base url, so let’s add a helper to do this.
  helpers do
    def base_url
      @base_url ||= "#{request.env['rack.url_scheme']}://{request.env['HTTP_HOST']}"
    end

    def json_params
      begin
        JSON.parse(request.body.read)
      rescue
        halt 400, { message:'Invalid JSON' }.to_json
      end
    end
  end

  # INDEX & FILTER

  get '/books' do
  books = Book.all
    # loop in the index endpoint that will go through each scope we defined and filter the books if a value was given for this specific scope.
    [:title, :isbn, :author].each do |filter|
      books = books.send(filter, params[filter]) if params[filter]
    end

    # replace it with our serializer method before calling json
    # materialize to javascript objects (json)
    books.map { |book| BookSerializer.new(book) }.to_json
  end




#  SHOW
# If the book is not found, we want to tell the client using the HTTP status 404
  get '/books/:id ' do |id|
      book = Book.where(id: id).first
      halt(404, { message:'Book Not Found'}.to_json) unless book
      BookSerializer.new(book).to_json
    end

# ADD
# Our create endpoint which will try to save the book and return 201 with the resource URL in the Location header or return 422 if some validations failed.
post '/books ' do
    book = Book.new(json_params)
    if book.save
      response.headers['Location'] = "#{base_url}/api/v1/books/#{book.id}"
      status 201
    else
      status 422
      body BookSerializer.new(book).to_json
    end
  end

  # cURL requests
  # curl -i -X POST -H "Content-Type: application/json" -d'{"title":"The Power Of Habit", "author":"Charles Duhigg", "isbn":"081298160X"}' http://localhost:4567/api/v1/books

# UPDATE
patch '/books/:id ' do |id|
    book = Book.where(id: id).first
    halt(404, { message:'Book Not Found'}.to_json) unless book
    if book.update_attributes(json_params)
      BookSerializer.new(book).to_json
    else
      status 422
      body BookSerializer.new(book).to_json
    end
  end

  # DELETE
  delete '/books/:id' do |id|
    book = Book.where(id: id).first
    book.destroy if book
    status 204
  end

end
