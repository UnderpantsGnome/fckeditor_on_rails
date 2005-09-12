require File.dirname(__FILE__) + '/../test_helper'
require 'fckeditor_controller'

# Re-raise errors caught by the controller.
class FckeditorController; def rescue_action(e) raise e end; end

class FckeditorControllerTest < Test::Unit::TestCase
  def setup
    @controller = FckeditorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
