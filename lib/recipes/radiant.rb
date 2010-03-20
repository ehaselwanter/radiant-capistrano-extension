namespace :deploy do

  after "deploy:cold", "deploy:radiant:bootstrap"
  after "deploy:migrate", "deploy:radiant:migrate:extensions"
  after "deploy:update" do
    run "mkdir #{latest_release}/cache"
    #run "cp #{latest_release}/config/database_eyecatch.yml #{latest_release}/config/database.yml"
    run "chmod -R g+w #{deploy_to}"
    run "[ ! -d #{shared_path}/assets ] && mkdir #{shared_path}/assets; true"
    run "[ ! -d #{shared_path}/galleries ] && mkdir #{shared_path}/galleries; true"
    run "[ ! -d #{shared_path}/uploads ] && mkdir #{shared_path}/uploads; true"
    run "[ ! -d #{shared_path}/system ] && mkdir #{shared_path}/system; true"
    run "ln -s #{shared_path}/assets #{latest_release}/public/assets"
    run "ln -s #{shared_path}/galleries #{latest_release}/public/galleries"
    run "ln -s #{shared_path}/uploads #{latest_release}/public/uploads"
    run "ln -s #{shared_path}/system #{latest_release}/public/system"
  end


    desc "clear cached copy, e.g. when changing submodule urls"
  task :clear_cached_copy do
    run <<-CMD
rm -rf #{shared_path}/cached-copy
    CMD
  end
  
  desc "Overridden deploy:cold for Radiant."
  task :cold do
    update
    radiant::bootstrap
    #start
  end

  desc "Restart Eyecatch"
  task :restart, :roles => :app do
    run "touch #{latest_release}/tmp/restart.txt"
  end

  namespace :radiant do
    desc "Radiant Bootstrap with empty template and default values."
    task :bootstrap do
      rake = fetch(:rake, "rake")
      rails_env = fetch(:rails_env, "production")

      run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} ADMIN_NAME=Administrator ADMIN_USERNAME=admin ADMIN_PASSWORD=radiant DATABASE_TEMPLATE=empty.yml OVERWRITE=true db:bootstrap"
    end

    namespace :migrate do
      desc "Runs migrations on extensions."
      task :extensions do
        rake = fetch(:rake, "rake")
        rails_env = fetch(:rails_env, "production")
        run "cd #{current_release}; #{rake} RAILS_ENV=#{rails_env} db:migrate:extensions"
      end
    end

    namespace :content do

      desc "rsync the local public content to the current radiant deployment"
      task :push_local_public_to_current_public do
        set :deploy_to_path,  File.join(deploy_to,"current","public")
        system "rsync -avz -e ssh public/ #{user}@#{ehost}:#{deploy_to_path}"
      end

      desc "fetch server production_db to local production_db"
      task :fetch_server_prod_to_local_prod do
        set :current_radiant, File.join(deploy_to,"current")
        run "cd #{current_radiant}; rake "
      end

      desc "fetch assets"
      task :fetch_assets do
        set :deploy_to_path,  File.join(deploy_to,"current","public","assets")
        system "rsync -Lavz -e ssh #{user}@#{ehost}:#{deploy_to_path}/ public/assets "
      end

      desc "fetch mailer system"
      task :fetch_system do
        set :deploy_to_path,  File.join(deploy_to,"current","public","system")
        system "rsync -Lavz -e ssh #{user}@#{ehost}:#{deploy_to_path}/ public/system "
      end

      desc "fetch gallery"
      task :fetch_galleries do
        set :deploy_to_path,  File.join(deploy_to,"current","public","galleries")
        system "rsync -Lavz -e ssh #{user}@#{ehost}:#{deploy_to_path}/ public/galleries "
      end
    end

  end
end

desc 'Dumps the production database to db/production_data.sql on the remote server'
task :remote_db_dump, :roles => :db, :only => { :primary => true } do
  rake = fetch(:rake, "rake")
  rails_env = fetch(:rails_env, "production")

  run "cd #{deploy_to}/#{current_dir} && " +
    "#{rake} RAILS_ENV=#{rails_env} db:database_dump --trace"
end

desc 'Loads the production database to db/production_data.sql on the remote server'
task :remote_db_load, :roles => :db, :only => { :primary => true } do
  rake = fetch(:rake, "rake")
  rails_env = fetch(:rails_env, "production")

  run "cd #{deploy_to}/#{current_dir} && " +
    "#{rake} RAILS_ENV=#{rails_env} db:production_data_load --trace"
end

desc 'Downloads db/production_data.sql from the remote production environment to your local machine'
task :remote_db_download, :roles => :db, :only => { :primary => true } do
  download("#{deploy_to}/#{current_dir}/db/production_data.sql", "db/production_data.sql", :via => :scp)
end

desc 'Uploads db/production_data.sql to the remote production environment from your local machine'
task :remote_db_upload, :roles => :db, :only => { :primary => true } do
  upload("db/development_data.sql", "#{deploy_to}/#{current_dir}/db/production_data.sql", :via => :scp)
end

desc 'Cleans up data dump file'
task :remote_db_cleanup, :roles => :db, :only => { :primary => true } do
  run "rm #{deploy_to}/#{current_dir}/db/production_data.sql"
end

desc 'Cleans up data dump file'
task :remote_cache_cleanup, :roles => :app do
  run "rm -rf #{deploy_to}/#{current_dir}/cache/* ;true"
end

desc 'Dumps, downloads and then cleans up the production data dump'
task :remote_db_runner do
  remote_db_dump
  remote_db_download
  remote_db_cleanup
end

desc 'Dumps, uploads and then cleans up the production data dump'
task :local_db_runner do
  remote_db_upload
  remote_db_load
  remote_cache_cleanup
  remote_db_cleanup
end




