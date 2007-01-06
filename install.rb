require 'fileutils'

FileUtils.ln_s(
  File.join(File.dirname(__FILE__), 'test', 'fckeditor_controller_test.rb'),
  File.join(File.dirname(__FILE__), '..', '..', 'test', 'functional', 
    'fckeditor_controller_test.rb')
) rescue puts <<-EOM
Unable to link the functional test, if you want to include fckeditor_on_rails
in your testing copy test/functional/fckeditor_controller_test.rb from the 
plugin directory into your app
EOM
