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

namespace '/api/v1' do

  before do
    content_type 'application/json'
  end

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

    # Using a method to access the book can save us
    # from a lot of repetitions and can be used
    # anywhere in the endpoints during the same
    # request
    def book
      @book ||= Book.where(id: params[:id]).first
    end

    # Since we used this code in both show and update
    # extracting it to a method make it easier and
    # less redundant
    def halt_if_not_found!
      halt(404, { message:'Book Not Found'}.to_json) unless book
    end

    def serialize(book)
      BookSerializer.new(book).to_json
    end
  end

  get '/books' do
    books = Book.all

    [:title, :isbn, :author].each do |filter|
      books = books.send(filter, params[filter]) if params[filter]
    end

    books.map { |book| BookSerializer.new(book) }.to_json
  end

  get '/books/:id' do |id|
    halt_if_not_found!
    serialize(book)
  end

  # We switched from an if...else statement
  # to using a guard clause which is much easier
  # to read and makes the flow more logical
  post '/books ' do
    book = Book.new(json_params)
    halt 422, serialize(book) unless book.save

    response.headers['Location'] = "#{base_url}/api/v1/books/#{book.id}"
    status 201
  end

  # Just like for the create endpoint,
  # we switched to a guard clause style to
  # check if the book is not found or if
  # the data is not valid
  patch '/books/:id' do |id|
    halt_if_not_found!
    halt 422, serialize(book) unless book.update_attributes(json_params)
    serialize(book)
  end

  delete '/books/:id' do |id|
    book.destroy if book
    status 204
  end
end
