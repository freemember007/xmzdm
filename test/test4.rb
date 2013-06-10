require 'rubygems'
require 'thread'
require 'activerecord'
require 'searchlogic'
require 'deal'

Deal.price_is("￥88").pname_is("咖啡").time_after(Time.now - 1.days).all.each do |deal|
  puts deal.title
  puts deal.time
  puts deal.pname
  puts deal.price
end
puts "---------"
puts Time.now
puts (Time.now - 1.days).strftime("%Y-%m-%d") 