#!/usr/bin/env ruby1.8

require 'rubygems'
require 'ruby-debug'
require 'active_record'
ActiveRecord::Base.logger = Logger.new(STDERR)

db_config = YAML::load(File.open('database.yml'))
ActiveRecord::Base.establish_connection(db_config["development"])

ActiveRecord::Schema.define do
    create_table :cruises do |table|
        table.column :description, :string
        table.column :link, :string
        table.column :cruiseline, :string
        table.column :length, :integer
        table.column :start_date, :string
        table.column :end_date, :string
        table.column :departure_port, :string
        table.column :arrival_port, :string
        table.column :price, :integer
    end
end
