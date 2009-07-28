namespace :radiant do
  namespace :extensions do
    namespace :capistrano do
      
      desc "Runs the migration of the Capistrano extension"
      task :migrate => :environment do
        require 'radiant/extension_migrator'
        if ENV["VERSION"]
          CapistranoExtension.migrator.migrate(ENV["VERSION"].to_i)
        else
          CapistranoExtension.migrator.migrate
        end
      end
      
      desc "Copies public assets of the Capistrano to the instance public/ directory."
      task :update => :environment do
        is_svn_or_dir = proc {|path| path =~ /\.svn/ || File.directory?(path) }
        puts "Copying assets from CapistranoExtension"
        Dir[CapistranoExtension.root + "/public/**/*"].reject(&is_svn_or_dir).each do |file|
          path = file.sub(CapistranoExtension.root, '')
          directory = File.dirname(path)
          mkdir_p RAILS_ROOT + directory, :verbose => false
          cp file, RAILS_ROOT + path, :verbose => false
        end
      end  
    end
  end
end
