#ActiveRecord::Base.logger = Logger.new(STDERR)
db_config = YAML::load(File.open('database.yml'))
ActiveRecord::Base.establish_connection(db_config["development"])

class Cruise < ActiveRecord::Base
end
