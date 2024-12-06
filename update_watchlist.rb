require 'csv'
require 'net/http'
require 'json'
require 'dotenv/load'

# Fonction pour ajouter un film à la Watchlist
def add_to_watchlist(film_uri)
  uri = URI("#{ENV['LETTERBOX_API_BASE_URL']}/user/#{ENV['LETTERBOX_USER_ID']}/watchlist")
  request = Net::HTTP::Post.new(uri)
  request["Authorization"] = "Bearer #{ENV['LETTERBOX_ACCESS_TOKEN']}"
  request["Content-Type"] = "application/json"
  request.body = { filmUri: film_uri }.to_json

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  if response.code.to_i == 201
    puts "Film ajouté à la Watchlist : #{film_uri}"
  else
    puts "Erreur lors de l'ajout à la Watchlist : #{film_uri} - #{response.body}"
  end
end

# Charger les films depuis watched.csv
def load_watched_movies(file_path)
  watched_movies = []
  CSV.foreach(file_path, headers: true) do |row|
    watched_movies << {
      name: row['Name'],
      year: row['Year'],
      uri: row['Letterboxd URI']
    }
  end
  watched_movies
end

# Charger les films depuis diary.csv
def load_diary_movies(file_path)
  diary_movies = []
  CSV.foreach(file_path, headers: true) do |row|
    diary_movies << {
      name: row['Name'],
      year: row['Year'],
      uri: row['Letterboxd URI']
    }
  end
  diary_movies
end

# Comparer les deux listes pour trouver les films manquants dans le Diary
def find_movies_to_add(watched_movies, diary_movies)
  diary_uris = diary_movies.map { |movie| movie[:uri] }.to_set
  watched_movies.reject { |movie| diary_uris.include?(movie[:uri]) }
end

# Charger les fichiers
watched_movies = load_watched_movies('watched.csv')
diary_movies = load_diary_movies('diary.csv')

# Identifier les films à ajouter
movies_to_add = find_movies_to_add(watched_movies, diary_movies)

# Ajouter les films manquants à la Watchlist
movies_to_add.each do |movie|
  add_to_watchlist(movie[:uri])
end

puts "Processus terminé. #{movies_to_add.size} films ajoutés à la Watchlist."
