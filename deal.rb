require 'rubygems'
require 'active_record'

class Deal < ActiveRecord::Base
  belongs_to :deal_site
  validates_uniqueness_of :title
  validates_presence_of :title, :image_url
end