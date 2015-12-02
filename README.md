Residential OpenStudio Measures
===============

Files to support residential measures in OpenStudio

## Using rake tasks (Rakefile)

To be able to use the rakefile, follow these steps:

1. Run ```gem sources -r https://rubygems.org/```
2. Run ```gem sources -a http://rubygems.org/```
3. Run ```gem install bundler```
4. Download DevKit at http://rubyinstaller.org/downloads/. Choose either the 32-bit or 64-bit version for use with Ruby 2.0 or above, depending on which version of Ruby you installed. Run the installer and extract to a directory (e.g., C:\RubyDevKit). Go to this directory and run ```ruby dk.rb init``` followed by ```ruby dk.rb install```
5. Run ```bundler```

Now you can run ```rake -T``` from the repo to see the list of possible rake tasks.

### Using rake task: update_resources

Use this task to update each measure's resource file to the corresponding resource file found in the top-level resources directory:

1. Update resources.csv found in the top-level resources directory
2. Run ```rake update_resources```
