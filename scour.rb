# 
# Finds cruise chains that meet criteria

MAXLAYOVER
price_per_night=50
max_cruises=10
max_price=10000

for cruise that is not round trip
	addcruise( cruise )
end

addcruise( cruises ) {
	whereweare = cruise[0].endport
	
	if is_overbudget( cruses ) ; then
		return 1
	elsif chain_is_continouous( cruises ); then
		print_cruise( cruises)
	else
		for cruise where startport = whereweare
			addcruise( [ cruise, cruises] )
		end
	end

}

is_overbudget ( cruises ) {
	for cruise in cruises
		totalprice = totalprice + cruise.price
		totaldays = totaldays + cruise.lenght
	end
	if totalprice > max_price || (totalprice/totaldays) > price_per_night; then
		return true
	else
		return false
	end
}

chain_is_continouous ( cruises) {
	if cruise[0].startport == cruise[-1].endport 
		return true
	else
		return false
	end
}
	
print_cruise( cruises ){
	for cruise in cruises.each
		cruise.print
	end
}
