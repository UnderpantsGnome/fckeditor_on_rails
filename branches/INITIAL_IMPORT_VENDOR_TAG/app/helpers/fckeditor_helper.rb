module FckeditorHelper
	def fckeditor( object, method, params = { }, options = { } )
		# setup params to be passed to js constructor
		width		= params[:width]		!= nil ? "'" + params[:width]		+ "'"	: 'null'
		height		= params[:height]		!= nil ? "'" + params[:height]		+ "'"	: 'null'
		toolbarSet	= params[:toolbarSet]	!= nil ? "'" + params[:toolbarSet]	+ "'"	: 'null'
		value		= params[:value]		!= nil ? "'" + params[:value]		+ "'"	: 'null'

		browser		= params[:browser]		|| FCKEDITOR_BROWSER
		basePath	= params[:base_path]	|| FCKEDITOR_BASE

		# setup the file browser
		custom_conf = "oFCKeditor.Config['ImageBrowserURL'] = " +
			"'#{basePath}editor/filemanager/browser/#{browser}/browser.html?Type=Image&Connector=/fckeditor/connector';" +
			"oFCKeditor.Config['LinkBrowserURL'] = " +
			"'#{basePath}editor/filemanager/browser/#{browser}/browser.html?Connector=/fckeditor/connector';"

		# quote this for the js tag
		basePath = "'#{basePath}'"

		# add custom config if there is one
		if params[:custom_config] != nil
			custom_conf += "oFCKeditor.Config['CustomConfigurationsPath'] = '" + params[:custom_config] + "';"
		end

		# set file path for browser if there is one, otherwise it will be
		# the FCKeditor mandated default of UserFiles
		if params[:user_files_dir] != nil
			custom_conf += "oFCKeditor.Config['UserFilesPath'] = '" + params[:user_files_dir] + "';"
		end

		# write it out to the browser
		text_area( object, method, options ) +
		javascript_tag("var oFCKeditor = new FCKeditor('#{object.to_s}[#{method.to_s}]', #{width}, #{height}, #{toolbarSet}, #{value}, #{basePath});" +
			custom_conf +
			'oFCKeditor.ReplaceTextarea();'
		)
	end
end
