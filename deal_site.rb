require 'rubygems'
require 'active_record'

class DealSite < ActiveRecord::Base
  has_many :deals
  validates_uniqueness_of :uid
  validates_presence_of :name, :uid
end


