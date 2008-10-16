module ApplicationHelper
	def fckeditor( object, method, fck_options = { }, options = { } )
		# setup fck_options to be passed to js constructor
		width = fck_options[:width] || 'null'
		height = fck_options[:height] || 'null'
		toolbarSet = fck_options[:toolbarSet] || Fckeditor.config[:toolbar_set] || 'Default'
		value = fck_options[:value] || 'null'

		browser		= fck_options[:browser]		|| Fckeditor.config[:browser]
		basePath	= fck_options[:base_path]	|| Fckeditor.config[:base]

		# setup the file browser
		custom_conf = "oFCKeditor.Config['ImageBrowserURL'] = " +
			"'#{basePath}editor/filemanager/browser/#{browser}/browser.html?Type=Image&Connector=/fckeditor/connector';" +
			"oFCKeditor.Config['LinkBrowserURL'] = " +
			"'#{basePath}editor/filemanager/browser/#{browser}/browser.html?Connector=/fckeditor/connector';"

		# add custom config if there is one
		custom_conf += "oFCKeditor.Config['CustomConfigurationsPath'] = '#{fck_options[:custom_config]}';" unless fck_options[:custom_config].nil?

		# set file path for browser if there is one, otherwise it will be
		# the FCKeditor mandated default of UserFiles
		custom_conf += "oFCKeditor.Config['UserFilesPath'] = '#{fck_options[:user_files_dir]}';" unless fck_options[:user_files_dir].nil?

		# write it out to the browser
		text_area( object, method, options ) +
		javascript_tag("var oFCKeditor = new FCKeditor('#{object.to_s}[#{method.to_s}]', '#{width}', '#{height}', '#{toolbarSet}', '#{value}', '#{basePath}');" +
			custom_conf +
			'oFCKeditor.ReplaceTextarea();'
		)
	end
end
