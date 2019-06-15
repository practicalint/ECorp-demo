#!/bin/bash

echo "Running"

# too new for ruby present sudo gem install bundler --no-ri --no-rdoc
sudo gem install bundler -v '1.17.3' --no-ri --no-rdoc  
sudo /usr/local/bin/bundle install --system

echo "Complete"
