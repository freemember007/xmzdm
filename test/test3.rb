require "rubygems"
require 'json'
require 'deal'

response = nil
open("pnamedict.json","r") do |file|
  response = file.read
end

json = JSON::parse(response)

@deal = Deal.find(:all, 
:limit => 10,   
:order => 'id DESC')

for deal in @deal

  json.each do |k,v|
    v.each do |pname|
      deal.catlog = k.to_i if deal.pname == pname
      deal.catlog.save
    end
  end
  puts deal.catlog
  puts deal.pname
end