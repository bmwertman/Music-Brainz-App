require 'bundler/setup'
Bundler.require(:default)
require_relative 'models/filestore'

before do
  MusicBrainz.configure do |c|
    c.app_name = "My Music App"
    c.app_version = "1.0"
    c.contact = "support@mymusicapp.com"
  end
end

get '/' do

  @all_historical_query_results = Filestore.all

  erb :index
end

post '/' do

    artist_string = ""
    #GET THE ARTIST MBID

    #query_name gets escaped because it turns into a normal "GET"
    query_name = URI.escape (params[:artist_name])

    url = "http://musicbrainz.org/ws/2/artist/?query=artist:#{query_name}&fmt=json"

    #HTTParty returns a Ruby hash since it's given JSON data
    response = HTTParty.get(url)

    mbid = response["artist"][0]["id"]
    if mbid != nil

    #GET THE DISC ID

    #construct the url and pass it to HTTParty
    disc_title = params{:disc_title}
  disc_url = "http://musicbrainz.org/ws/2/freedb/?query=title#{disc_title}"
    discs_hash = HTTParty.get(disc_url)

    #Parse the hash of hashes returned by HTTParty & return discs whose match "score" equals "100"
    show_disc = discs_hash["metadata"]["freedb_disc_list"]["freedb_disc"].select{|i| i["score"] == "100"}

    #Return the "id" of the first disc in the array whose "score" was "100"
    disc_id = show_disc[0]["id"]

    else

      artist_name = "Not Available"

    end

    unless disc_id || mbid == nil
    #USE THE ARTIST MBID AND DISC ID TO GET THE COVER ART

    #construct the url & pass Cover Art Archive the MBID and disc id to return the cover art for the disc

      disc_image_url = "http://coverartarchive.org/release/#{mbid}/#{disc_id}.jpg"
      @disc_image = HTTParty.get(disc_image_url)

    else

      @disc_image = "None Available"

    end

    artist_string = "#{params[:artist_name]}, #{disc_title}"
    Filestore.create(artist_string)
    redirect '/'
  end

