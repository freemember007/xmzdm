# encoding: utf-8
require 'rubygems'
# require 'sinatra'
require 'rufus/scheduler'

puts '加载定时任务'
scheduler = Rufus::Scheduler.start_new
scheduler.every '30m' do
  require './grab.rb'
end