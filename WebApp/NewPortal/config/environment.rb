# Load the rails application
require File.expand_path('../application', __FILE__)

# NOTE: This WebApp is a single user application
$USER = ENV['USER'] || 'unknown'

# Initialize the rails application
NewPortal::Application.initialize!
