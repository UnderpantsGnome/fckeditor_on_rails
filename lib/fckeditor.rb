class Fckeditor
  @@config = nil

  def self.config
    @@config ||= self.load_config
  end

  def self.ensure_dirs_exist
    dirs = %w( Image Media Flash File )
    base = File.expand_path(File.join(RAILS_ROOT, 'public', 
      self.config[:upload_dir]))

    dirs.each do |dir|
      FileUtils.mkdir_p(File.join(base, dir))
    end
    true
  end

  def self.load_config
    [File.join(RAILS_ROOT, 'config/fckeditor.yml'), 
      File.join(File.dirname(__FILE__), '..', 'config', 'fckeditor.yml')].each do |config|
      if File.exist?(config)
        fck_conf = YAML.load_file(config)
        unless fck_conf[RAILS_ENV.to_sym].nil?
          @@config = fck_conf[:defaults].merge(fck_conf[RAILS_ENV.to_sym])
        else
          @@config = fck_conf[:defaults]
        end
      end
    end
    @@config
  end
end

require File.join(File.dirname(__FILE__), '../app/helpers/application_helper.rb')
