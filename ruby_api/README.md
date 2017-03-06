#How To Create a Ruby API with Sinatra
[Source](https://x-team.com/blog/how-to-create-a-ruby-api-with-sinatra/)


##Let’s build a simple Ruby API with Sinatra!

To learn more about Sinatra and its simplicity, we are going to build a book library called BookList. It might sound simple like this, because it is. We will only have a Book model and the needed endpoints to interact with them. The simplicity of our application semantics will allow us to focus on the tricky parts of web API creation.

Due to the simplicity of our application, we will only use the `server.rb` to store all of BookList source code.

We need some kind of persistence to store our books so let’s use MongoDB and the Mongoid gem. Not having to run migrations makes it much easier to use MongoDB for this tutorial, especially since we are not using Rails.

Let’s install MongoDB first. If you are using a Mac, just use `Homebrew` to install it:

`brew update && brew install mongodb`  

If you are using a different operating system, check the following links to install MongoDB (you should really use Homebrew on OS X though):

* [Windows](https://docs.mongodb.com/v3.0/tutorial/install-mongodb-on-windows/)
* [Ubuntu](https://docs.mongodb.com/manual/tutorial/install-mongodb-on-ubuntu/)

Once we have Mongodb, we need to install [mongoid](https://github.com/mongodb/mongoid). To do so, we can just run the following command:

`gem install mongoid`

Next, we need a configuration file to tell our application where to find the MongoDB database. At the root of the application folder: `touch mongoid.config`.  
In it, we  just specify where our database is running for the development environment.


- Creating data inside IRB

`irb(main):001:0> require './server'  
=> true`

To create the indexes for the Book model

`Book.create_indexes`

In IRB, you can create some seed data. Eg:

`Book.create(title:'Dune', author:'Frank Herbert', isbn:'0441172717') `


- Add a Gemfile to keep our dependencies in one place.
At the root of your application folder: `touch Gemfile`  

Inside the file:

```

# Gemfile
source 'https://rubygems.org'

gem 'sinatra'  
gem 'mongoid'  

# Required to use some advanced features of# Sinatra, like namespaces
gem 'sinatra-contrib'  

```
After that, run bundle install to get everything in place. From now on, you will use `bundle exec ruby server.rb` to start the web API.


ps: Note that we could also have created a `config.ru` file and run the application with `Rack` but to keep this tutorial short, simply using the `bundle` command is easier.

- Adding a namespace
Creating a namespace for our API endpoints is important if we want to be able to version it and add a v2 later. The best practice here is usually to define the API version using HTTP headers.

The namespace `/api/v1` was added after the root endpoint. We will add all the books endpoints inside this namespace block. We also need to require `sinatra-namespace` to have the namespace feature.

All the books endpoints (Index, Show, Create, Update, Delete) are added inside this namespace block.

- Creating a Book JSON serializer

 We don’t necessarily want to send all the book attributes to the client. To fix this, we are going to create a small Ruby class that will serialize books into JSON documents.

Our serializer is going to be a `PORO (Plain-Old Ruby Object)` with one method called `as_json` that will be called whenever `to_json` is called on an instance.
