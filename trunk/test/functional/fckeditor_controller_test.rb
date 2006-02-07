require File.dirname(__FILE__) + '/../test_helper'
require 'fckeditor_controller'
require 'fileutils'
include FileUtils

# Re-raise errors caught by the controller.
class FckeditorController; def rescue_action(e) raise e end; end

class FckeditorControllerTest < Test::Unit::TestCase
  TMP_DIR = "tmp/"
  IMG_DIR = "Image"
  IMG_SRC = "../../public/images"
  IMG1 = "rails.png"
  IMG2 = "rails(1).png"
  
  def setup
    @controller = FckeditorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    
    @test_dir = File.dirname($PROGRAM_NAME)
    @tmp_dir = "#{@test_dir}/#{TMP_DIR}"
    @img_dir = "#{@tmp_dir}/#{IMG_DIR}"
    
    # Create test upload structure
    rm_rf(@tmp_dir)
    Dir.mkdir(@tmp_dir)
    Dir.mkdir(@img_dir)
    Dir.mkdir("#{@img_dir}/foo")
    
    # Copy a test file into the structure
    cp("#{@test_dir}/#{IMG_SRC}/#{IMG1}", @img_dir)
  end

  def teardown
    rm_rf(@tmp_dir)
  end
   
  # Get directory and file list
  def test_get_folders_and_files
    get :connector, { :Command => 'GetFoldersAndFiles', :ServerPath => @tmp_dir}
    
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'connector',
               :attributes => {:command => "GetFoldersAndFiles", :resourcetype => 'Image'}
    assert_tag :tag => 'currentfolder',
               :attributes => {:url => "/UserFiles/Image/", :path => "/"},
               :parent => {:tag => "connector"}
    assert_tag :tag => 'folders',
               :parent => {:tag => "connector"}
    assert_tag :tag => 'folder',
               :attributes => {:name => "foo"},
               :parent => {:tag => "folders"}
    assert_tag :tag => 'files',
               :parent => {:tag => "connector"}
    assert_tag :tag => 'file',
               :parent => {:tag => "files"},
               :attributes => {:name => IMG1}
  end
   
  # Get directory and file list
  def test_get_folders
    get :connector, { :Command => 'GetFolders', :ServerPath => @tmp_dir}
    
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'connector',
               :attributes => {:command => "GetFolders", :resourcetype => 'Image'}
    assert_tag :tag => 'currentfolder',
               :attributes => {:url => "/UserFiles/Image/", :path => "/"},
               :parent => {:tag => "connector"}
    assert_tag :tag => 'folders',
               :parent => {:tag => "connector"}
    assert_tag :tag => 'folder',
               :attributes => {:name => "foo"},
               :parent => {:tag => "folders"}
    assert_no_tag :tag => 'file'
  end

  # File Upload
  def test_file_upload
    # Make sure there are no files uploaded
    get :connector, { :Command => 'GetFoldersAndFiles', :ServerPath => @tmp_dir, :CurrentFolder => '/foo/'}
    assert_response :success
    assert_template 'files_and_folders'
    assert_no_tag :tag => 'file',
                  :attributes => {:name => IMG1}

    # Do the upload
    heman = uploaded_jpeg("#{@img_dir}/#{IMG1}")
    post :connector, { :Command => 'FileUpload', :ServerPath => @tmp_dir, :CurrentFolder => '/foo/', :NewFile => heman}
    assert_response :success
    assert_template 'upload_file'
    assert_tag :tag => 'script',
               :attributes => {:type => "text/javascript"},
               :content => "UploadCompleted(0, '#{IMG1}'"

    # Make sure the file exists
    get :connector, { :Command => 'GetFoldersAndFiles', :ServerPath => @tmp_dir, :CurrentFolder => '/foo/'}
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'file',
               :attributes => {:name => IMG1}
  end

  # File Upload (muliple)
  def test_file_upload_multiple
    # Do the upload
    heman = uploaded_jpeg("#{@img_dir}/#{IMG1}")
    post :connector, { :Command => 'FileUpload', :ServerPath => @tmp_dir, :CurrentFolder => '/foo/', :NewFile => heman}
    assert_response :success
    assert_template 'upload_file'
    assert_tag :tag => 'script',
               :attributes => {:type => "text/javascript"},
               :content => /UploadCompleted\(0, '#{IMG1}'/

    # Do the upload again
    post :connector, { :Command => 'FileUpload', :ServerPath => @tmp_dir, :CurrentFolder => '/foo/', :NewFile => heman}
    assert_response :success
    assert_template 'upload_file'
    assert_tag :tag => 'script',
               :attributes => {:type => "text/javascript"},
               :content => "UploadCompleted\(201, '#{IMG2}'"  # 201 status return indicates it was renamed

    # Make sure the files exists
    get :connector, { :Command => 'GetFoldersAndFiles', :ServerPath => @tmp_dir, :CurrentFolder => '/foo/'}
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'file',
               :attributes => {:name => IMG1}
    assert_tag :tag => 'file',
               :attributes => {:name => IMG2}
  end

  # Get create folder
  def test_create_folder
    get :connector, { :Command => 'CreateFolder', :ServerPath => @tmp_dir, :NewFolderName => 'bar'}
    
    assert_response :success
    assert_template 'create_folder'
    assert_tag :tag => 'connector',
               :attributes => {:command => "CreateFolder", :resourcetype => 'Image'}
    assert_tag :tag => 'currentfolder',
               :attributes => {:url => "/UserFiles/Image/", :path => "/"},
               :parent => {:tag => "connector"}
    assert_tag :tag => 'error',
               :parent => {:tag => "connector"},
               :attributes => {:number => "0"}
  end

  # Get create folder
  def test_create_folder_existing
    get :connector, { :Command => 'CreateFolder', :ServerPath => @tmp_dir, :NewFolderName => 'foo'}
    
    assert_response :success
    assert_template 'create_folder'
    assert_tag :tag => 'connector',
               :attributes => {:command => "CreateFolder", :resourcetype => 'Image'}
    assert_tag :tag => 'currentfolder',
               :attributes => {:url => "/UserFiles/Image/", :path => "/"},
               :parent => {:tag => "connector"}
    assert_tag :tag => 'error',
               :parent => {:tag => "connector"},
               :attributes => {:number => "101"}
  end
  # get us an object that represents an uploaded file
  def uploaded_file(path, content_type="application/octet-stream", filename=nil)
    filename ||= File.basename(path)
    t = Tempfile.new(filename)
    FileUtils.copy_file(path, t.path)
    (class << t; self; end;).class_eval do
      alias local_path path
      define_method(:original_filename) { filename }
      define_method(:content_type) { content_type }
    end
    return t
  end

  # a PNG helper
  def uploaded_png(path, filename=nil)
    uploaded_file(path, 'image/png', filename)
  end

  # a JPEG helper
  def uploaded_jpeg(path, filename=nil)
    uploaded_file(path, 'image/jpeg', filename)
  end

  # a GIF helper
  def uploaded_gif(path, filename=nil)
    uploaded_file(path, 'image/gif', filename)
  end
end
