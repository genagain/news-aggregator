require 'sinatra'
require 'pry'
require 'pg'
require 'csv'

def db_connection
  begin
    connection = PG.connect(dbname: "news_aggregator_development")
    yield(connection)
  ensure
    connection.close
  end
end

#create
def add_article(title, url, description)
  db_connection do |conn|
    conn.exec("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [title, url, description])
  end
end

def articles_from_csv
  articles_array = []
  CSV.foreach('articles.csv', headers: true, headers_converters: :symbol) do |row|
    articles_array << row.to_hash
  end
  articles_array
end

def csv_to_db(articles)
  articles.each do |articles_array|
    db_connection.each do |conn|
      conn.exec("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [articles[:title], articles[:url], articles[:description]])
    end
  end
end

def get_all_articles
  sql = "SELECT * FROM articles"
  all_articles = db_connection { |conn|conn.exec(sql) }
  all_articles.to_a
end

def all_submissions_correct?(params)
  params.each_key { |key| return false if params[key].empty? }
  true
end

def article_to_params(params)
  params_string = '?'

  params.each do |key, value|
    params_string += "#{key}=#{value}&"
  end

  params_string
end

def get_error_messages(params)
  messages = []

  params.each do |key, value|
    messages << "Please input a #{key}" if value.empty?
  end
  messages
end


get '/' do
  errors = !params.empty? ? get_error_messages(params) : ''

  all_articles = get_all_articles
  erb :home, locals: { all_articles: all_articles, errors: errors}
end


post '/' do
  title = params[:title]
  url = params[:url]
  description = params[:description]

  if all_submissions_correct?(params)
    add_article(title, url, description)
    redirect '/'
  else
    redirect "/#{article_to_params(params)}"
  end
end


articles_csv = articles_from_csv
csv_to_db(articles_csv)
