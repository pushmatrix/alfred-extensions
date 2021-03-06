# encoding: UTF-8
class Forvo
  require 'open-uri'
  require 'base64'

  SEARCH_URL = "http://www.forvo.com/word/"
  DOWNLOAD_LINKS_REGEX = /a.*onclick=\"Play\((.*)\);.*/

  def initialize(query, language)
    @query, @language = query, language
  end

  def self.download(query)
    forvo = Forvo.new query, "#sv"

    download_links = forvo.fetch_download_links
    return "Word '#{query.join(" ")}' not found" unless download_links.any?

    forvo.download download_links.first
  end

  def fetch_download_links
    html = open_query_page
    match_links = html.match DOWNLOAD_LINKS_REGEX

    match_links ? parse_download_links(match_links[1..-1]) : []
  end

  def download(download_link)
    filename = parse_filename download_link
    file_path =  "/tmp/#{filename}"

    Net::HTTP.start("audio.forvo.com") do |http|
      resp = http.get("/mp3/#{download_link}")
      open(file_path, "wb") do |file|
        file.write(resp.body)
      end
    end

    file_path
  end


  private

  def open_query_page
    begin
      puts query_page_url
      x= open(query_page_url).read
      File.open("/Users/db/Desktop/jizz.biz", "w") do |f|
        f.puts @query
      end
      x
    rescue Exception => exception
      puts "Exception: #{exception}"
    end
  end

  def query_page_url
    begin
    URI.escape("#{SEARCH_URL}#{@query.join(' ')}#{@language}".encode('utf-8'))
    rescue Exception => e
      puts e
    end
  end

  def parse_download_links(params)
    params.collect do |param|
      encoded_links = param.split(",").collect {|x| x.gsub("'", "")}
      mp3_link = encoded_links[1]

      ::Base64.decode64(mp3_link)
    end
  end

  def parse_filename(download_link)
    download_link.match /.*\/.*\/(.*)/
    $1
  end
end
