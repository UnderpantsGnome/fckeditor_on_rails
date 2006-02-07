class FckeditorController < ApplicationController
  # this may not be very Rubyesque, it's my first run at Ruby code
  # I'm sure it will get better over time
  # feel free to point out better ways to do thigs in Ruby
  # if you can do it without being abusive ;)
  before_filter :setup, :except => 'index'
  
  def index
    if RAILS_ENV != 'development'
      render(:nothing => true)
    end
  end

  # figure out who needs to handle this request
  def connector    
    if @params[:Command] == 'GetFoldersAndFiles' || @params[:Command] == 'GetFolders'
      get_folders_and_files(@params)
    elsif @params[:Command] == 'CreateFolder'
      create_folder(params)
    elsif @params[:Command] == 'FileUpload'
      upload_file(@params)
    end
  end

  private
  def setup
    defaultParams
    status = 200
    
    # Check parameters for correctness
    if (@params[:Command] !~ /^(GetFolders|GetFoldersAndFiles|CreateFolder|FileUpload)$/)
      render :text => "Command parameter malformed: \"#{@params[:Command]}\"", status => 405
    elsif (@params[:Type] !~ /^(File|Image|Flash|Media)$/)
      render :text => "Type parameter malformed: \"#{@params[:Type]}\"", status => 405
    elsif (@params[:CurrentFolder] !~ /^\/(.+\/)*$/)
      render :text => "CurrentFolder parameter malformed: \"#{@params[:CurrentFolder]}\"", status => 405
    else
      # Make sure necessary directories exist
      unless File.directory?(@params[:ServerPath])
        Dir.mkdir(@params[:ServerPath])
      end   
      @dir = "#{params[:ServerPath]}#{params[:Type]}#{params[:CurrentFolder]}"
      @url = "/UserFiles/#{params[:Type]}#{params[:CurrentFolder]}"
      @error = 0
    end
  end

  # generate a directory listing
  def get_folders_and_files(params)
    @files    = Array.new
    @dirs     = Array.new

    d = Dir.new(@dir)

    d.each  { |x|
      # skip . and .. I'm sure there's a better way to handle this
      if x != '.' && x != '..'
        # actual file system path
        full_path = "#{@dir}/#{x}";

        # found a directory add it to the list
        if File.directory?(full_path)
          @dirs << x
        #if we only want directories, skip the files
        elsif params[:Command] == 'GetFoldersAndFiles' && File.file?(full_path)
          size = File.size(full_path)

          if size != 0 && size < 1024
            size = 1
          else
            size = File.size(full_path) / 1024
          end

          @files << { :name => x, :size => size };
        end
      end
    }

    render(:template => 'fckeditor/files_and_folders', :layout => false)

  rescue
    render(:template => 'fckeditor/files_and_folders', :layout => false)

  end

  # create a new directory
  def create_folder(params)
    new_dir   = @dir + params[:NewFolderName]
    d = Dir.mkdir(new_dir)

    render(:template => 'fckeditor/create_folder', :layout => false)

  rescue Errno::EEXIST
    # directory already exists
    @error    = 101
    render(:template => 'fckeditor/create_folder', :layout => false)
  rescue Errno::EACCES
    # permission denied
    @error    = 103
    render(:template => 'fckeditor/create_folder', :layout => false)
  rescue
    # any other error
    @error    = 110
    render(:template => 'fckeditor/create_folder', :layout => false)

  end

  # upload a new file
  # currently the FCKeditor docs only allow for 2 errors here
  # file renamed and invalid file name
  # not sure how to catch invalid file name yet
  # I'm thinking there should be a permission denied error as well
  def upload_file(params)
    counter   = 1
    @file_name  = params[:NewFile].original_filename

    # break it up into file and extension
    # we need this to check the types and to build new names if necessary
    ext = File.extname(@file_name)
    path = File.basename(@file_name, ext)

    # check to make sure this extension isn't in deny and is in allow
    if ! in_array(FCKEDITOR_FILE_TYPES[params[:Type]]['deny'], ext)
       in_array(FCKEDITOR_FILE_TYPES[params[:Type]]['allow'], ext)
      while File.exist?("#{@dir}#{@file_name}")
        @file_name    = "#{path}(#{counter})#{ext}"
        @error  = 201
        counter     = counter.next
      end

      n = File.open("#{@dir}#{@file_name}", 'wb') { |f| f.write(params[:NewFile].read) }
    else
      # invalid file type
      @error  = 202
   end

    render(:template => 'fckeditor/upload_file', :layout => false)
  end

  # helper to setup pathing info that is common to all methods
  def defaultParams
    if RAILS_ENV == 'production' or !@params.has_key?(:ServerPath)
      # Allow destination directory to be overridden, otherwise it must be that which is configured
      @params[:ServerPath]  = "#{RAILS_ROOT}/public/UserFiles/"
    end
    
    # Set defaults
    @params[:Type]            = "Image" unless @params.has_key?(:Type)
    @params[:CurrentFolder]   = "/" unless @params.has_key?(:CurrentFolder)
  end

  # helper to see if a value exists in an array
  # I'm sure there is a more Rubyesque way to do this
  # somebody let me know
  def in_array(haystack, needle)
    if haystack != nil && needle != nil
      haystack.each { |val|
        if val == needle
          return true
        end
      }
    end

    return false
  end
end
