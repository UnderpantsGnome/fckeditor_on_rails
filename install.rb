require 'fileutils'

dest_file = File.join(File.dirname(__FILE__), '..', '..', '..', 'test', 
  'functional', 'fckeditor_controller_test.rb')

FileUtils.rm(dest_file) rescue nil

FileUtils.cp(
  File.join(File.dirname(__FILE__), 'test', 'functional', 'fckeditor_controller_test.rb'),
  dest_file
) rescue puts <<-EOM
Unable to copy the functional test, if you want to include fckeditor_on_rails
in your testing copy #{File.dirname(__FILE__)}/test/functional/fckeditor_controller_test.rb 
from the plugin directory into test/functional/
EOM
