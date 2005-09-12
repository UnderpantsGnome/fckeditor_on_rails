class FckeditorController < ApplicationController
	# this may not be very Rubyesque, it's my first run at Ruby code
	# I'm sure it will get better over time
	# feel free to point out better ways to do thigs in Ruby
	# if you can do it without being abusive ;)

	def index
		if RAILS_ENV != 'development'
			render(:nothing => true)
		end
	end

	# figure out who needs to handle this request
	def connector
		if params[:Command] == 'GetFoldersAndFiles' || params[:Command] == 'GetFolders'
			get_folders_and_files(params)
		elsif params[:Command] == 'CreateFolder'
			create_folder(params)
		elsif params[:Command] == 'FileUpload'
			upload_file(params)
		end
	end

	# generate a directory listing
	def get_folders_and_files(params)
		params		= appendParams(params)
		@files		= Array.new
		@dirs		= Array.new
		d			= Dir.new(params[:dir])
		f_count		= 0
		d_count 	= 0

		d.each  { |x|
			# skip . and .. I'm sure there's a better way to handle this
			if x != '.' && x != '..'
				# actual file system path
				full_path = "#{params[:dir]}/#{x}";

				# found a directory add it to the list
				if File.directory?(full_path)
					@dirs[d_count] = x
					d_count = d_count.next
				#if we only want directories, skip the files
				elsif params[:Command] == 'GetFoldersAndFiles' && File.file?(full_path)
					size = File.size(full_path)

					if size != 0 && size < 1024
						size = 1
					else
						size = File.size(full_path) / 1024
					end

					@files[f_count] = { :name => x, :size => size };
					f_count = f_count.next
				end
			end
		}

		render(:template => 'fckeditor/files_and_folders', :layout => false)

	rescue
		render(:template => 'fckeditor/files_and_folders', :layout => false)

	end

	# create a new directory
	def create_folder(params)
		params		= appendParams(params)
		new_dir		= params[:dir] + params[:NewFolderName]
		d			= Dir.mkdir(new_dir)

		render(:template => 'fckeditor/create_folder', :layout => false)

	rescue Errno::EEXIST
		# directory already exists
		@error		= 101
		render(:template => 'fckeditor/create_folder', :layout => false)
	rescue Errno::EACCES
		# permission denied
		@error		= 103
		render(:template => 'fckeditor/create_folder', :layout => false)
	rescue
		# any other error
		@error		= 110
		render(:template => 'fckeditor/create_folder', :layout => false)

	end

	# upload a new file
	# currently the FCKeditor docs only allow for 2 errors here
	# file renamed and invalid file name
	# not sure how to catch invalid file name yet
	# I'm thinking there should be a permission denied error as well
	def upload_file(params)
		params		= appendParams(params)
		counter		= 1
		@file_name	= params[:NewFile].original_filename
		path		= nil
		ext			= nil

		# break it up into file and extension
		# we need this to check the types and to build new names if necessary
		/^(.*)(\..*)$/.match(@file_name)
		path		= Regexp.last_match(1)
		ext			= Regexp.last_match(2)

		# check to make sure this extension isn't in deny and is in allow
		if ! in_array(FCKEDITOR_FILE_TYPES[params[:Type]]['deny'], ext) &&
			 in_array(FCKEDITOR_FILE_TYPES[params[:Type]]['allow'], ext)

			while File.exist?("#{params[:dir]}#{@file_name}")
				@file_name		= "#{path}(#{counter})#{ext}"
				params[:error]	= 201
				counter			= counter.next
			end

			File.open("#{params[:dir]}#{@file_name}", 'w') { |f| f.write(params[:NewFile].read) }
		else
			# invalid file type
			params[:error]	= 202
		end

		render(:template => 'fckeditor/upload_file', :layout => false)
	end

	# helper to setup pathing info that is common to all methods
	# is there is a more Rubyesque way to do this?
	# somebody let me know
	def appendParams(params)
		params[:error]		= 0
		params[:base_dir]	= FCKEDITOR_UPLOADS || 'UserFiles'
		params[:url]		= "#{params[:base_dir]}#{params[:Type]}#{params[:CurrentFolder]}".gsub(/\/+/, '/')
		params[:dir]		= "#{RAILS_ROOT}/public#{params[:url]}"

		return params
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
