#!/usr/bin/env ruby1.8
require 'rubygems'
require 'ruby-debug'
require 'active_record'
require 'database_junk.rb'

# 
# Finds cruise chains that meet criteria
$max_layover = 2
$max_ppn = 100
$max_price = 40000
$start_location = "Tampa, FL"
#$start_location = "Seattle, WA"


def is_overbudget ( cruises ) 
	for cruise in cruises.each
		totalprice = totalprice.to_i + cruise.price.to_i
		totaldays = totaldays.to_i + cruise.length.to_i
	end
	if totalprice > $max_price || (totalprice/totaldays) > $max_ppn
		return true
	else
		return false
	end
end # is_overbudget


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

def potential_cruises( departure_port, date )
	# Gather all cruises and return the list
	# take into account layover
	list = []
	d = Date.parse(date)
	for counter in 0..$max_layover
	   search_date = (d + counter).to_s
	   list += Cruise.find(:all, :conditions => ['departure_port = ? AND start_date = ?', departure_port, search_date])
	end
	return list
end

def main
	# Start with an empty array of cruises
	cruise_list = []

	# Initial search, starting at our selected start_location
	puts "Beginning Search at starting location: " + $start_location
	starting_cruises = Cruise.find_all_by_departure_port($start_location)
	total_starting_cruises = starting_cruises.length
	counter = 0
	for cruise1 in starting_cruises.each
           counter = counter + 1
	   puts "Progress: " + counter.to_s + " / " + total_starting_cruises.to_s
	   # don't even bother checking for over budget until the second cruise
	   for cruise2 in potential_cruises( cruise1.arrival_port, cruise1.end_date )
	      cruise_list = [ cruise1, cruise2 ]
	      break if is_overbudget( cruise_list )
	      for cruise3 in potential_cruises( cruise2.arrival_port, cruise2.end_date )
	         cruise_list = [ cruise1, cruise2, cruise3 ]
	         break if is_overbudget( cruise_list )
	         print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
	         for cruise4 in potential_cruises( cruise3.arrival_port, cruise3.end_date )
	            cruise_list = [ cruise1, cruise2, cruise3, cruise4 ]
	            break if is_overbudget( cruise_list )
	            print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
	            for cruise5 in potential_cruises( cruise4.arrival_port, cruise4.end_date )
	               cruise_list = [ cruise1, cruise2, cruise3, cruise4, cruise5 ]
	               break if is_overbudget( cruise_list )
	               print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
	               for cruise6 in potential_cruises( cruise5.arrival_port, cruise5.end_date )
	                  cruise_list = [ cruise1, cruise2, cruise3, cruise4, cruise5, cruise6 ]
	                  break if is_overbudget( cruise_list )
	                  print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
	                  for cruise7 in potential_cruises( cruise6.arrival_port, cruise6.end_date )
	                     cruise_list = [ cruise1, cruise2, cruise3, cruise4, cruise5, cruise6, cruise7 ]
	                     break if is_overbudget( cruise_list )
	                     print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
	   	          for cruise8 in potential_cruises( cruise7.arrival_port, cruise7.end_date )
	                        cruise_list = [ cruise1, cruise2, cruise3, cruise4, cruise5, cruise6, cruise7, cruise8 ]
	                        break if is_overbudget( cruise_list )
	                        print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
	   	             for cruise9 in potential_cruises( cruise8.arrival_port, cruise8.end_date )
	                           cruise_list = [ cruise1, cruise2, cruise3, cruise4, cruise5, cruise6, cruise7, cruise8, cruise9 ]
	                           break if is_overbudget( cruise_list )
	                           print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
	   	                for cruise10 in potential_cruises( cruise9.arrival_port, cruise9.end_date )
	                               cruise_list = [ cruise1, cruise2, cruise3, cruise4, cruise5, cruise6, cruise7, cruise8, cruise9, cruise10 ]
	                               break if is_overbudget( cruise_list )
	                               print_cruise( cruise_list ) if ( cruise_list[-1].arrival_port == $start_location && cruise_list.length > 1 && cruise_list.map{ |x| x.departure_port }.uniq.length > 1 )
                                   end
                                end
                             end
                          end
                       end
                    end
                 end
              end
	   end
	end
end #main

main
