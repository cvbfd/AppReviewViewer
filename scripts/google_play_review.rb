# -*- encoding: utf-8 -*-

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'net/http'
require 'net/https'

$LOAD_PATH << File.dirname(__FILE__)
require 'abstract_review'

class GooglePlayReview < AbstractReview

  def initialize
    super
  end

  def get_reviews(html, app_id)
    dates = []
    titles = []
    bodies = []
    stars = []
    users = []
    versions = []
    devices = []
    i = 0

    doc = Nokogiri.HTML(html)
    doc.xpath("//h4[@class='review-title']").each do |node|
      titles.push(node.text)
    end

    doc.xpath("//p[@class='review-text']").each do |node|
      bodies.push(node.text)
    end

    doc.xpath("//span[@class='doc-review-date']").each do |node|
      dates.push(node.text)
    end

    doc.xpath("//div[@class='ratings goog-inline-block']").each do |node|
      stars.push(node.attributes['title'].value)
    end

    doc.xpath("//strong").each do |node|
      users.push(node.text)
    end

    doc.xpath("//div[@class='doc-review']").each do |node|
      versions.push(get_version(node.text))
      devices.push(get_device(node.text))
    end

    items = [];
    count = stars.size - 1
    (0..count).each do |key|
      item = {
        :star => stars[key],
        :user => users[key],
        :date => dates[key],
        :title => titles[key],
        :body => bodies[key],
        :version => versions[key],
        :device => devices[key],
        :app_id => app_id
      }
      items.push(item)
    end
    return items
  end

  def fetch_reviews(app_id, pages)
    (0..pages).each do |page|
      puts "processing ID:#{app_id} #{(page+1).to_s}/#{(pages+1).to_s}...\n"

        http = Net::HTTP.new('play.google.com', 443)
      http.use_ssl = true
      path = "/store/getreviews"
      data = "id=#{app_id}&reviewSortOrder=2&reviewType=1&pageNum=#{page}"
        response = http.post(path, data)
      html_string = JSON.parse(response.body.split("\n")[1])['htmlContent']
      reviews = get_reviews(html_string, app_id)
      insert_reviews(reviews)
    end
  end

  def get_version(text)
    if /（([^）]+)、バージョン ([^）]+)）/ =~ text
      version = $2
    end
    return version
  end

  def get_device(text)
    device = nil
    if /（([^）]+)、バージョン (.+)）/ =~ text
      device = $1
    end
    return device
  end
end
