require 'net/http'
require 'json'
require 'csv'
require 'date'
require 'dotenv'

Dotenv.load

# URL de l'API Trello
TRELLO_URL = "https://api.trello.com/1/boards/#{ENV['BOARD_ID']}/cards"

# Fonction pour traduire un titre de film en anglais via TMDb
def translate_to_english(title)
  base_url = "https://api.themoviedb.org/3/search/movie"
  uri = URI(base_url)
  params = {
    api_key: ENV['TMDB_API_KEY'],
    query: title,
    language: 'en-US'
  }
  uri.query = URI.encode_www_form(params)

  response = Net::HTTP.get(uri)
  data = JSON.parse(response)

  puts data

  # Récupérer le titre anglais du premier résultat
  if data['results'] && !data['results'].empty?
    data['results'][0]['title'] # Titre anglais
  else
    title # Si aucun résultat trouvé, retourner le titre original
  end
rescue StandardError => e
  puts "Erreur de traduction pour '#{title}': #{e.message}"
  title
end

# Récupérer les cartes depuis Trello
uri = URI(TRELLO_URL)
uri.query = URI.encode_www_form({ key: ENV['TRELLO_API_KEY'], token: ENV['TRELLO_TOKEN'] })
response = Net::HTTP.get(uri)
cards = JSON.parse(response)

# Création d'un fichier CSV au format Letterboxd
seen_titles = Set.new # Pour suivre les titres déjà rencontrés

CSV.open('films_export_letterboxd_diary.csv', 'w', write_headers: true, headers: ['Title', 'Year', 'Directors', 'Rating', 'Date', 'Liked', 'Rewatch']) do |csv|
  cards.each do |card|
    original_title = card['name'] # Titre original de la carte Trello

    # Ignorer les cartes qui commencent par "Liste des films vus en {date}"
    next if original_title.match?(/^Liste des films vus en \d{4}/)

    description = card['desc'] || "" # Description de la carte
    labels = card['labels'] || [] # Étiquettes de la carte

    # Traduire le titre en anglais
    title = translate_to_english(original_title)

    # Extraire l'année du film si présente dans le titre ou description
    year = original_title[/\((\d{4})\)/, 1]

    # Exemple : Réalisateurs (à adapter si dans la description)
    directors = nil

    # Exemple : Note (si défini dans la description ou autre convention)
    rating = nil

    # Utiliser la due date comme date de visionnage si disponible
    due_date = card['due'] # La due date de la carte (exemple : "2018-01-01T12:58:00.000Z")
    begin
      date = due_date ? Date.parse(due_date).strftime('%Y-%m-%d') : nil
    rescue ArgumentError
      date = nil
    end

    # Vérifier si la carte a une étiquette "coup de cœur"
    liked = labels.any? { |label| label['name'].casecmp?('coup de coeur') } ? 'Yes' : 'No'

    # Vérifier si le film a déjà été vu
    rewatch = seen_titles.include?(title) ? 'Yes' : 'No'

    # Ajouter le titre au set des titres vus
    seen_titles.add(title)

    # Ajouter la ligne au fichier CSV
    csv << [title, year, directors, rating, date, liked, rewatch]
  end
end

puts "Export terminé. Le fichier 'films_export_letterboxd_diary.csv' est prêt."