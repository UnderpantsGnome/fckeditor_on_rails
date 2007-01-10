require File.dirname(__FILE__) + '/../test_helper'
require 'fckeditor_controller'
require 'fileutils'
include FileUtils

# Re-raise errors caught by the controller.
class FckeditorController; def rescue_action(e) raise e end; end

class FckeditorControllerTest < Test::Unit::TestCase
  FILE_DIR = File.join(RAILS_ROOT, 'vendor', 'plugins', 'fckeditor_on_rails', 
    'test', 'files')
  IMG1       = 'rails.png'
  IMG2       = 'rails(1).png'
  IMG2_RE    = 'rails\\(1\\).png'
  EXECUTABLE = 'bad_file.exe'
  
  def setup
    rm_rf(Fckeditor.config[:upload_dir])
    Fckeditor.ensure_dirs_exist
    @controller = FckeditorController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def teardown
    rm_rf(File.join('public', Fckeditor.config[:upload_dir]))
  end
   
  # Get directory and file list
  def test_get_folders_and_files
    get :connector, { 
      :Command => 'GetFoldersAndFiles', 
      :Type => 'Image',
      :CurrentFolder => '/'
    }
    
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'connector',
               :attributes => { 
                 :command => "GetFoldersAndFiles", 
                 :resourcetype => 'Image' 
               }
    assert_tag :tag => 'currentfolder',
               :parent => { :tag => "connector" },
               :attributes => { 
                 :url => "/#{Fckeditor.config[:upload_dir]}Image/", 
                 :path => "/" 
               }
    assert_tag :tag => 'folders',
               :parent => { :tag => "connector" }
    assert_tag :tag => 'files',
               :parent => { :tag => "connector" }
  end
   
  # Get directory list
  def test_get_folders
    get :connector, { 
      :Command => 'GetFolders', 
      :Type => 'Image',
      :CurrentFolder => '/'
    }
    
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'connector',
               :attributes => { 
                 :command => "GetFolders", 
                 :resourcetype => 'Image' 
               }
    assert_tag :tag => 'currentfolder',
               :parent => { :tag => "connector" },
               :attributes => { 
                 :url => "/#{Fckeditor.config[:upload_dir]}Image/", 
                 :path => "/" 
                }
    assert_tag :tag => 'folders',
               :parent => { :tag => "connector" }
    assert_no_tag :tag => 'file'
  end
  
  # File Upload
  def test_file_upload
    # Make sure there are no files uploaded
    get :connector, { 
      :Command => 'GetFolders', 
      :Type => 'Image',
      :CurrentFolder => '/'
    }
    assert_response :success
    assert_template 'files_and_folders'
    assert_no_tag :tag => 'file', :attributes => { :name => IMG1 }

    # Do the upload
    heman = uploaded_jpeg("#{FILE_DIR}/#{IMG1}")
    post :connector, { 
      :Command => 'FileUpload', 
      :Type => 'Image', 
      :CurrentFolder => '/', 
      :NewFile => heman
    }
    assert_response :success
    assert_template 'upload_file'
    assert_tag :tag => 'script',
               :attributes => { :type => "text/javascript" },
               :content => /UploadCompleted\(0, '#{IMG1}'/
      
    # Make sure the file exists
    get :connector, { 
      :Command => 'GetFoldersAndFiles', 
      :Type => 'Image',
      :CurrentFolder => '/'
    }
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'file', :attributes => { :name => IMG1 }
  end
  
  # File Upload (multiple), test rename
  def test_file_upload_multiple
    # Do the upload
    heman = uploaded_jpeg("#{FILE_DIR}/#{IMG1}")
    post :connector, { 
      :Command => 'FileUpload', 
      :Type => 'Image', 
      :CurrentFolder => '/', 
      :NewFile => heman
    }
    assert_response :success
    assert_template 'upload_file'
    assert_tag :tag => 'script',
               :attributes => { :type => "text/javascript" },
               :content => /UploadCompleted\(0, '#{IMG1}'/
  
    # Do the upload again
    heman = uploaded_jpeg("#{FILE_DIR}/#{IMG1}")
    post :connector, { 
      :Command => 'FileUpload', 
      :Type => 'Image', 
      :CurrentFolder => '/', 
      :NewFile => heman
    }
    assert_response :success
    assert_template 'upload_file'
    # 201 status return indicates it was renamed
    assert_tag :tag => 'script',
               :attributes => { :type => "text/javascript" },
               :content => /UploadCompleted\(201, '#{IMG2_RE}'/
  
    # Make sure the files exist
    get :connector, { 
      :Command => 'GetFoldersAndFiles', 
      :CurrentFolder => '/', 
      :Type => 'Image' 
    }
    assert_response :success
    assert_template 'files_and_folders'
    assert_tag :tag => 'file', :attributes => { :name => IMG1 }
    assert_tag :tag => 'file', :attributes => { :name => IMG2 }
  end
  
  # Get create folder
  def test_create_folder
    get :connector, { 
      :Command => 'CreateFolder', 
      :Type => 'Image',
      :CurrentFolder => '/',
      :NewFolderName => 'bar'
    }
    
    assert_response :success
    assert_template 'create_folder'
    assert_tag :tag => 'connector',
               :attributes => {
                 :command => "CreateFolder", 
                 :resourcetype => 'Image'
               }

    assert_tag :tag => 'currentfolder',
               :parent => { :tag => "connector" },
               :attributes => {
                 :url => "/#{Fckeditor.config[:upload_dir]}Image/", 
                 :path => "/"
               }
               
    assert_tag :tag => 'error',
               :parent => { :tag => "connector" },
               :attributes => { :number => "0" }
  end
  
  # Get create folder
  def test_create_folder_existing
    # call it once to make sure it's there
    get :connector, { 
      :Command => 'CreateFolder', 
      :Type => 'Image',
      :CurrentFolder => '/',
      :NewFolderName => 'foo'
    }
    
    # call it again for the actual test
    get :connector, { 
      :Command => 'CreateFolder', 
      :Type => 'Image',
      :CurrentFolder => '/',
      :NewFolderName => 'foo'
    }

    assert_response :success
    assert_template 'create_folder'
    assert_tag :tag => 'connector',
               :attributes => {
                 :command => "CreateFolder", 
                 :resourcetype => 'Image'
               }

    assert_tag :tag => 'currentfolder',
               :parent => { :tag => "connector" },
               :attributes => {
                 :url => "/#{Fckeditor.config[:upload_dir]}Image/", 
                 :path => "/"
               }
               
    assert_tag :tag => 'error',
               :parent => { :tag => "connector" },
               :attributes => { :number => "101" }
  end

  def test_executable_upload
    heman = uploaded_file("#{FILE_DIR}/#{EXECUTABLE}")
    post :connector, { 
      :Command => 'FileUpload', 
      :Type => 'Image', 
      :CurrentFolder => '/', 
      :NewFile => heman
    }

    assert_response :success
    assert_template 'upload_file'
    # 202 status return indicates file type not allowed
    assert_tag :tag => 'script',
               :attributes => { :type => "text/javascript" },
               :content => /UploadCompleted\(202, '#{EXECUTABLE}'/
  end

  def test_upload_above_safe
    heman = uploaded_file("#{FILE_DIR}/#{EXECUTABLE}")
    post :connector, { 
      :Command => 'FileUpload', 
      :Type => 'Image', 
      :CurrentFolder => '../../../',
      :NewFile => heman
    }
    
    # we flat out reject these attempts 
    assert_response :forbidden
  end

  def test_list_above_safe
    get :connector, { 
      :Command => 'GetFoldersAndFiles', 
      :CurrentFolder => '../../../',
      :Type => 'Image' 
    }
    
    # we flat out reject these attempts 
    assert_response :forbidden
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
