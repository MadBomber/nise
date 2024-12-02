# To use the Bootstrap Rake task for you own application create
# yaml files in db/bootstrap containing your data.
#
# E.g. to fill the 'users' table, create the yaml file db/bootstrap/users.yml
# 
# Next, run 'rake db:bootstrap' to re-initialize your database.
#

namespace :db do
  desc "Recreates the development database and loads the bootstrap fixtures from db/boostrap."
  task :bootstrap do |task_args|
    mkdir_p File.join(RAILS_ROOT, 'log')
    
    require 'rubygems' unless Object.const_defined?(:Gem)
        
    %w(environment db:drop db:create db:migrate db:bootstrap:load tmp:create).each { |t| Rake::Task[t].execute task_args}

  end # end of task :bootstrap do |task_args|


  namespace :bootstrap do

    desc "Load fixtures into the current environment's database. Load specific fixtures using FIXTURES=x,y. Load from subdirectory in test/fixtures using FIXTURES_DIR=z. Specify an alternative path (eg. spec/fixtures) using FIXTURES_PATH=spec/fixtures."
    task :load => :environment do
      require 'active_record/fixtures'

      puts "Loading bootstrap tables:"

      ActiveRecord::Base.establish_connection(Rails.env)
      base_dir     = File.join [Rails.root, ENV['FIXTURES_PATH'] || %w{db bootstrap}].flatten
      fixtures_dir = File.join [base_dir, ENV['FIXTURES_DIR']].compact

      (ENV['FIXTURES'] ? ENV['FIXTURES'].split(/,/) : Dir["#{fixtures_dir}/**/*.{yml,csv}"].map {|f| f[(fixtures_dir.size + 1)..-5] }).each do |fixture_file|
        puts "  #{fixture_file} ..."
        ActiveRecord::Fixtures.create_fixtures(fixtures_dir, fixture_file)
      end
    end

  end # end of namespace :bootstrap do

end # end of namespace :db do

