#!/usr/bin/env ruby
# Abuses cruises weekly's TOS (I presume) by scraping their pages extracting cruise info

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'ruby-debug'
require 'active_record'
ActiveRecord::Base.logger = Logger.new(STDERR)

def fetch(url)
	response = ""
	filename = "cache/" + url.split("/")[-1]
	
	begin
	#If the file doesn't exist, download it
	  if ! File.exists?(filename)
	     open(url) { |f| response = f.read }
	     File.open(filename, 'w') {|f| f.write(response) }
             # Give the website a break
             sleep(5)
	  end
	  
          # Open the saved file eitherway
          open(filename) { |f| response = f.read }
	  thedoc = Hpricot(response)

	rescue Exception => e
	  print e, "\n"
	  debugger
	end
	return thedoc
end

def scrape_num_pages(url)
	puts "Fetching " + url + " ..."
	doc = fetch(url)
	number = (doc/'//*[@id="ctl00_ContentPlaceHolder1_ctl00_ListHandler1_ctl00_ListHeader1_celCount"]').inner_html.to_s.split[-1]
	puts "We have " + number + " of pages to go through..."
	return number.to_i
end

def scrape_page(page_num)
	url = "http://www.travelweekly.com/Cruise/Cruise-Search?pg=" + page_num.to_s + "&stype=CRUS&st=price"
	puts "Fetching " + url
	doc = fetch(url)
	for result in (doc/"/html/body/div/div[2]/form/div[1]/div/div/div/div/ul/li").each
		if ( (result).inner_html =~ /.*No departures.*/ )
			puts "No departures for this cruise. Continuing."
		else
	  		begin
	  			# Extract info
	  			title = result.search("#browse-results-name")
	  			description = title.inner_html
	  			cruiseinfo=(result/"div[3]/")
	  			cruiseline = (result/"div[3]/div/span/b[1]").inner_html.to_s
	  			length = result.search("#browse-results-name").inner_html.split[0].to_i
	  			departure_port = (result/"/div[3]/div/span/b[2]").each.first.following.to_html.split("<")[0]
	  			arrival_port = (result/"/div[3]/div/span/b[3]").each.first.following.to_html.split("<")[0]
	  			# Multiple leavings for the same trip
			    	if ( (result).inner_html =~ /.*See more sailing dates for this cruise.*/ )
					# If there are more dates, we have to scrap the all page
					all_url = "http://www.travelweekly.com" + (result/"div[4]/table/tbody/tr/td[1]").to_html.split('"')[3] + "&all=1"
					all_doc = fetch(all_url)
					instances = (all_doc/"table/tbody/tr/td[1]")	
				else
					instances = (result/"div[4]/table/tbody/tr/td[1]").each
			   	end # end if sailng dates
				
	  			for instance in instances
					next if ( (instance/"a").to_html =~ /.*See more sailing dates for this cruise.*/ )
					# Most cases, we have a link in the top 
					if ( (instance/"a").to_html =~ /.*href.*/ ) 
	  					cruise_id = (instance/"a").to_html.split('"')[1].split("=")[1]
	  					link = "http://www.travelweekly.com" +  (instance/"a").to_html.split('"')[1]
					else # Other case, where the instance is not a link
						cruise_id = (result/"div[4]/table/tbody/tr/td[1]/a").to_html.split('"')[1].split('=')[1]
	  					link = "http://www.travelweekly.com" +  (result/"div[4]/table/tbody/tr/td[1]/a").to_html.split('"')[1]
					end
	  				start_date = (instance/"a").inner_html
	  				prices = instance.following.inner_html.split("$")
					next if ( prices ==  ["Contact cruise line for pricing & availability"] )
	  				prices = prices.collect{ |e| e.gsub('-','') }
	  				prices = prices - [ "" ]
	  				prices = prices.collect{ |e| e.gsub(',','').to_i }
	  				price = prices.min
					if price == 0 
						puts "Price is 0? Something is bogus. Figure it out"
						debugger
					end
	  				insert_cruise( cruise_id, description, link, cruiseline, length, start_date, departure_port, arrival_port, price ) 

	  				puts "Finished with that instance"
	  			
	  			end # end instance loop
	  		 rescue 
	  		 	puts "result exception raised, this html is not parseable for some reason"
	  		 	debugger
	  		end # end begin 
		end # end if
	end #end for result
	puts "Analyzing the page..."
end

def insert_cruise( cruise_id, description, link, cruiseline, length, start_date, departure_port, arrival_port, price ) 

			puts ""
			puts "Cruise ID: " + cruise_id
			puts "Got a cruise: " + description
			puts "Link: " + link
			puts "Cruiseline: " + cruiseline
			puts "Length: " + length.to_s
			puts "Start Date: " + start_date
			puts "Departure Port: " + departure_port
			puts "Arrival Port: " + arrival_port
			puts "Price: " + price.to_s
			puts ""
end

def main 
#   number_of_pages = scrape_num_pages("http://www.travelweekly.com/Cruise/Cruise-Search?stype=CRUS")
   # Only the first 105 pages or so have prices  
   for page in 1..105
   	scrape_page(page)
   	puts "scraping page " + page.to_s
   end
end

main
