#!/usr/bin/env ruby

require 'rubygems'
require 'ruby-debug'
require 'active_record'
ActiveRecord::Base.logger = Logger.new(STDERR)

db_config = YAML::load(File.open('database.yml'))
ActiveRecord::Base.establish_connection(db_config["development"])

ActiveRecord::Schema.define do
    create_table :cruises do |table|
        table.column :cruise_id, :string
        table.column :description, :string
        table.column :link, :string
        table.column :cruiseline, :string
        table.column :length, :string
        table.column :start_date, :string
        table.column :departure_port, :string
        table.column :arrival_port, :string
        table.column :price, :string
    end
end
