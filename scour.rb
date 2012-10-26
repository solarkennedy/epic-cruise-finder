#!/usr/bin/env ruby1.8
require 'rubygems'
require 'ruby-debug'
require 'active_record'
require 'database_junk.rb'

# 
# Finds cruise chains that meet criteria
$max_layover = 0
$max_ppn = 60
$max_cruises = 10
$max_price = 40000
$start_location = "Tampa, FL"
#$start_location = "Seattle, WA"


def is_overbudget ( cruises ) 
	for cruise in cruises.each
		totalprice = totalprice.to_i + cruise.price.to_i
		totaldays = totaldays.to_i + cruise.length.to_i
	end
	if totalprice > $max_price || (totalprice/totaldays) > $max_ppn || cruises.length > $max_cruises
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
	end

	different_ports = new_cruise_list.map{ |x| x.departure_port }.uniq.length
	if ( whereweare == $start_location && new_cruise_list.length > 1 && different_ports > 1 )
		print_cruise( new_cruise_list )
	end

	# Otherwise, we sail on 
	# I'm a lazy sql dude. Here we iterate over our max layover dates, searching for cruises
	# on each of the possible layover days
	d = Date.parse(cruise.end_date)
	for counter in 0..$max_layover
		search_date = (d + counter).to_s
		for next_cruise in Cruise.find(:all, :conditions => ['departure_port = ? AND start_date = ?', whereweare, search_date])
			addcruise( new_cruise_list, next_cruise )
		end
	end
end # end add cruise

def print_cruise( cruises )
	puts "We found a cruise!"
	for cruise in cruises.each
		puts "	" + cruise.description.to_s + " (" + cruise.link.to_s + ")"
		totalprice = totalprice.to_i + cruise.price.to_i
                totaldays = totaldays.to_i + cruise.length.to_i
	end
	puts "Finishing Port: " + cruises[-1].arrival_port.to_s
	puts "Total Price:  " + totalprice.to_s
	puts "Total Length: " + totaldays.to_s
	puts "Average PPN:  " + (totalprice/totaldays).to_s
	puts ""
end #end print_cruise

def main
	# Start with an empty array of cruises
	cruise_list = []

	# Initial search, starting at our selected start_location
	puts "Beginning Search at starting location: " + $start_location
	starting_cruises = Cruise.find_all_by_departure_port($start_location)
	total_starting_cruises = starting_cruises.length
	counter = 1
	for cruise in starting_cruises.each
		puts "Progress: " + counter.to_s + " / " + total_starting_cruises.to_s
		addcruise( cruise_list, cruise )
		counter = counter + 1
		
	end
end #main

main
