#!/usr/bin/env ruby1.8
# Abuses cruises weekly's TOS (I presume) by scraping their pages extracting cruise info

require 'rubygems'
require 'open-uri'
require 'hpricot'
require 'ruby-debug'
require 'active_record'
require 'database_junk.rb'
require 'parsedate'
require 'chronic'

#ActiveRecord::Base.logger = Logger.new(STDERR)
#db_config = YAML::load(File.open('database.yml'))
#ActiveRecord::Base.establish_connection(db_config["development"])


def fetch(url)
	puts "now fetchin " + url
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
	  	#	begin
	  			# Extract info
	  			title = result.search("#browse-results-name")
	  			description = title.inner_html
	  			cruiseinfo=(result/"div[3]/")
	  			cruiseline = (result/"div[3]/div/span/b[1]").inner_html.to_s
	  			length = result.search("#browse-results-name").inner_html.split[0].to_i

				# if the cruisinfo page has a more link, that means it is longer and has a long list of ports
				if ( cruiseinfo.inner_html =~ /.*more \.\.\./ ) 
					begin
					morelink=(result/"div[4]/table/tbody/tr/td[1]").to_html.split('"')[3]
					#morelink=(result/"div[4]/table/tbody/tr/td[1]").to_html.split('"')[3].split('?')[0]
					more_url = "http://www.travelweekly.com" + morelink + "&all=1"
					moreinfo = fetch(more_url)
					itinerary_rows = (moreinfo/"/html/body/div/div[2]/form/div[1]/div[3]/div/div[1]/table/tr/td")
					unsanitized_departure_port = itinerary_rows[-2].innerHTML.gsub(/Arrive at /, "").split("-")[0]
					rescue
					puts "moreinfo broke"
					debugger
					end
	
				else
	  				unsanitized_departure_port = (result/"/div[3]/div/span/b[2]").each.first.following.to_html.split("<")[0].strip
				end
				departure_port = sanitize_port( unsanitized_departure_port )

				# Grab the last part of this string, delemited by a semi-colon, and strip it
	  			unsanitized_arrival_port = (result/"/div[3]/div/span/b[3]").each.first.following.to_html.split("<")[0].split(";")[-1].strip.gsub(/"/, "")
				arrival_port = sanitize_port( unsanitized_arrival_port )
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
	  					link = "http://www.travelweekly.com" +  (instance/"a").to_html.split('"')[1]
					else # Other case, where the instance is not a link
	  					link = "http://www.travelweekly.com" +  (result/"div[4]/table/tbody/tr/td[1]/a").to_html.split('"')[1]
					end
					begin
	  				start_date = Date.parse((instance).innerText)
	  				end_date = start_date + length
					rescue
					debugger
					end
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

	  				insert_cruise( description, link, cruiseline, length, start_date, end_date, departure_port, arrival_port, price ) 

	  				puts "Finished with that instance"
	  			
	  			end # end instance loop

	  	#	 rescue 
	  	#	 	puts "result exception raised, this html is not parseable for some reason"
	  #		 	debugger
	  	#	end # end begin 
		end # end if
	end #end for result
	puts "Analyzing the page..."
end

def insert_cruise( description, link, cruiseline, length, start_date, end_date, departure_port, arrival_port, price ) 
#	begin
		puts "Inserting cruise into db"
		cruise = Cruise.create(
			:description => description,
			:link => link,
			:cruiseline => cruiseline,
			:length => length,
			:start_date => start_date,
			:end_date => end_date,
			:departure_port => departure_port,
			:arrival_port => arrival_port,
			:price => price
			)

			puts ""
			puts "Got a cruise: " + description
			puts "Link: " + link
			puts "Cruiseline: " + cruiseline
			puts "Length: " + length.to_s
			puts "Start Date: " + start_date.to_s
			puts "End Date: " + end_date.to_s
			puts "Departure Port: " + departure_port
			puts "Arrival Port: " + arrival_port
			puts "Price: " + price.to_s
			puts ""
#	rescue 
#		puts "insert_cruise failed, figure it out"
#		debugger
#	end
end

def sanitize_port( p )
	# For some reason this is human entered, and needs some sanitizing. 
	# It sucks. If someone has a better way to do this, merge-request me
	
	# Yea, Im not normalizing my database entries. Sue me

	# This list is parsed out of the "departure_port" list, so it will match up exactly 
	# and the program will work. A different scraper will probably have a different list of departure ports

	case
		when p.match(/Amsterdam/i)
			r = "Amsterdam, Netherlands"
		when p.match(/Aukland/i)
			r = "Auckland, New Zealand"
		when p.match(/Baltimore/i)
			r = "Baltimore, MD"
		when p.match(/Bangkok/i)
			r = "Bangkok, Thailand"
		when p.match(/Barcelona/i)
			r = "Barcelona, Spain"
		when p.match(/Bari/i)
			r = "Bari, Italy"
		when p.match(/Beijing/i)
			r = "Beijing, China"
		when p.match(/Benoa/i)
			r = "Benoa, Indonesia"
		when p.match(/Boston/i)
			r = "Boston, MA"
		when p.match(/Bridgetown/i)
			r = "Bridgetown, Barbados"
		when p.match(/Brisbane/i)
			r = "Brisbane, Queensland, Australia"
		when p.match(/Buenos Aires/i)
			r = "Buenos Aires, Argentina"
		when p.match(/Buzios/i)
			r = "Buzios, Brazil"
		when p.match(/Callao/i)
			r = "Callao, Peru"
		when p.match(/Cape Liberty/i)
			r = "Cape Liberty, NJ"
		when p.match(/Cape Town/i)
			r = "Cape Town, South Africa"
		when p.match(/Casablanca/i)
			r = "Casablanca, Morocco"
		when p.match(/Casa De Campo/i)
			r = "Casa De Campo, Dominican Republic"
		when p.match(/Charleston/i)
			r = "Charleston, SC"
		when p.match(/Chennai/i)
			r = "Chennai, India"
		when p.match(/Civitavecchia/i)
			r = "Civitavecchia, Italy"
		when p.match(/Colon/i)
			r = "Colon, Panama"
		when p.match(/Copenhagen/i)
			r = "Copenhagen, Denmark"
		when p.match(/Dover/i)
			r = "Dover, England"
		when p.match(/Dubai/i)
			r = "Dubai, United Arab Emirates"
		when p.match(/Dublin/i)
			r = "Dublin, Ireland"
		when p.match(/Ensenada/i)
			r = "Ensenada, Baja California Norte, Mexico"
		when p.match(/Fort Lauderdale/i)
			r = "Fort Lauderdale, FL"
		when p.match(/Galveston/i)
			r = "Galveston, TX"
		when p.match(/Genoa/i)
			r = "Genoa, Italy"
		when p.match(/Haifa/i)
			r = "Haifa, Israel"
		when p.match(/Hamburg/i)
			r = "Hamburg, Germany"
		when p.match(/Harwich/i)
			r = "Harwich, England"
		when p.match(/Havana/i)
			r = "Havana, Cuba"
		when p.match(/Heraklion/i)
			r = "Heraklion, Crete Island, Greece"
		when p.match(/Hong Kong/i)
			r = "Hong Kong, Hong Kong"
		when p.match(/Honolulu/i)
			r = "Honolulu, HI"
		when p.match(/Istanbul/i)
			r = "Istanbul, Turkey"
		when p.match(/Jacksonville/i)
			r = "Jacksonville, FL"
		when p.match(/Keil/i)
			r = "Kiel, Germany"
		when p.match(/Kobe/i)
			r = "Kobe, Japan"
		when p.match(/Laem Chabang/i)
			r = "Laem Chabang, Thailand"
		when p.match(/Le Havre/i)
			r = "Le Havre, France"
		when p.match(/Limon/i)
			r = "Limon, Costa Rica"
		when p.match(/Lisbon/i)
			r = "Lisbon, Portugal"
		when p.match(/Livorno/i)
			r = "Livorno, Italy"
		when p.match(/Long Beach/i)
			r = "Long Beach, CA"
		when p.match(/Los Angeles/i)
			r = "Los Angeles, CA"
		when p.match(/Malaga/i)
			r = "Malaga, Spain"
		when p.match(/Manaus/i)
			r = "Manaus, Brazil"
		when p.match(/Marseille/i)
			r = "Marseille, France"
		when p.match(/Melbourne/i)
			r = "Melbourne, Victoria, Australia"
		when p.match(/Messina/i)
			r = "Messina, Sicily Island, Italy"
		when p.match(/Miami/i)
			r = "Miami, FL"
		when p.match(/Monte Carlo/i)
			r = "Monte Carlo, Monaco"
		when p.match(/Montreal/i)
			r = "Montreal, PQ"
		when p.match(/Mumbia/i)
			r = "Mumbai, India"
		when p.match(/Naples/i), p.match(/Napoli/i)
			r = "Naples, Italy"
		when p.match(/New Orleans/i)
			r = "New Orleans, LA"
		when p.match(/New York/i)
			r = "New York, NY"
		when p.match(/Norfolk/i)
			r = "Norfolk, VA"
		when p.match(/Norfolk/i)
			r = "Oranjestad, Aruba"
		when p.match(/Palma de Mallorca/i)
			r = "Palma de Mallorca, Mallorca Island, Balearic Islands, Spain"
		when p.match(/Papeete/i)
			r = "Papeete, Society Islands, French Polynesia"
		when p.match(/Perth/i)
			r = "Perth, Western Australia, Australia"
		when p.match(/Piraeus/i), p.match(/Athens/i)
			r = "Piraeus, Greece"
		when p.match(/Port Canaveral/i)
			r = "Port Canaveral, FL"
		when p.match(/Puerto Caldera/i)
			r = "Puerto Caldera, Costa Rica"
		when p.match(/Quebec/i)
			r = "Quebec, PQ"
		when p.match(/Ravenna/i)
			r = "Ravenna, Italy"
		when p.match(/Reykjavik/i)
			r = "Reykjavik, Iceland"
		when p.match(/Rio de Janeiro/i)
			r = "Rio de Janeiro, Brazil"
		when p.match(/Rotterdam/i)
			r = "Rotterdam, Netherlands"
		when p.match(/San Diego/i)
			r = "San Diego, CA"
		when p.match(/San Francisco/i)
			r = "San Francisco, CA"
		when p.match(/San Juan/i)
			r = "San Juan, Puerto Rico"
		when p.match(/Santa Cruz de Tenerife/i)
			r = "Santa Cruz de Tenerife, Tenerife Island, Canary Islands, Spain"
		when p.match(/Santos/i)
			r = "Santos, Brazil"
		when p.match(/Savona/i)
			r = "Savona, Italy"
		when p.match(/Seattle/i)
			r = "Seattle, WA"
		when p.match(/Seward/i)
			r = "Seward, AK"
		when p.match(/Shanghai/i)
			r = "Shanghai, China"
		when p.match(/Sharm el Sheikh/i), p.match(/Sokhna/i)
			r = "Sharm el Sheikh, Egypt"
		when p.match(/Singapore/i)
			r = "Singapore, Singapore"
		when p.match(/Southampton/i)
			r = "Southampton, England"
		when p.match(/Stockholm/i)
			r = "Stockholm, Sweden"
		when p.match(/Sydney/i)
			r = "Sydney, New South Wales, Australia"
		when p.match(/Tampa/i)
			r = "Tampa, FL"
		when p.match(/Tianjin/i)
			r = "Tianjin, China"
		when p.match(/Tilbury/i)
			r = "Tilbury, England"
		when p.match(/Tokyo/i)
			r = "Tokyo, Japan"
		when p.match(/Toulon/i)
			r = "Toulon, France"
		when p.match(/Trieste/i)
			r = "Trieste, Italy"
		when p.match(/Valparaiso/i)
			r = "Valparaiso, Chile"
		when p.match(/Vancouver/i)
			r = "Vancouver, BC"
		when p.match(/Venice/i), p.match(/Venezia/i)
			r = "Venice, Italy"
		when p.match(/Whittier/i)
			r = "Whittier, AK"
		when p.match(/Xingang/i)
			r = "Xingang, China"
		when p.match(/Yokohama/i)
			r = "Yokohama, Japan"
		else
			puts "Your sanitize_port function didn't work for " + p
			puts "Figure it out"
			exit
	end # end case
	return r
end
	
def main 
#   number_of_pages = scrape_num_pages("http://www.travelweekly.com/Cruise/Cruise-Search?stype=CRUS")
   # Only the first 105 pages or so have prices  
   for page in 1..10
   	scrape_page(page)
   	puts "scraping page " + page.to_s
   end
end


main
