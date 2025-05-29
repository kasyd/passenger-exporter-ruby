#!/bin/bash
cd /opt/passenger_exporter || exit 1

# Loads RVM (so bash -l can work properly)
source /etc/profile.d/rvm.sh

# Activates RVM and sets the Ruby version
rvm use ruby-2.7.8

# Runs the exporter with the absolute paths to Ruby and Bundler
/home/ubuntu/.rvm/gems/ruby-2.7.8/bin/bundle exec /usr/share/rvm/rubies/ruby-2.7.8/bin/ruby exporter.rb