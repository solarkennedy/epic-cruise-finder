#!/usr/bin/env ruby1.8
require 'rubygems'
require 'ruby-debug'
require 'active_record'
require 'database_junk.rb'

# 
# Finds cruise chains that meet criteria
$max_layover = 5
$max_ppn = 50
$max_cruises = 10
$max_price = 10000
$start_location = "Seattle, WA"


def is_overbudget ( cruises ) 
	for cruise in cruises.each
		totalprice = totalprice + cruise.price
		totaldays = totaldays + cruise.lenght
	end
	if totalprice > max_price || (totalprice/totaldays) > price_per_night
		return true
	else
		return false
	end
end # is_overbudget

def addcruise( cruise_list, cruise ) 
	whereweare = cruise.arrival_port
	new_cruise_list = cruise_list + [ cruise ]
	
	# quit right away if we are now over budget after the cruise just added
	if ( is_overbudget( new_cruise_list ) )
		return 1
	#  if we are back were we are started, then we are done
	elsif ( whereweare == $start_location )
		print_cruise( cruises)
		return 0
	# Otherwise, we sail on 
	else
		for next_cruise in Cruisefind_all_by_departure_port( whereweare ).each
			addcruise( new_cruise_list, next_cruise )
		end
	end
end # end add cruise

def print_cruise( cruises )
	for cruise in cruises.each
		cruise.print
	end
end #end print_cruise

def main
	# Start with an empty array of cruises
	cruise_list = []

	# Initial search, starting at our selected start_location
	puts "Searching for curises starting at" + $start_location
	for cruise in Cruise.find_all_by_departure_port($start_location).each
		addcruise( cruise_list, cruise )
	end
end #main

main
