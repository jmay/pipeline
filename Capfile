load "deploy"

require 'capistrano/ext/multistage'

set :deploy_via, :remote_cache
set :scm, :git
set :repository, "git@github.com:jmay/pipeline.git" 

desc "Tasks to execute after code update"
task :after_update_code do
  run "rm -rf #{release_path}/tmp"
  run "rm -rf #{release_path}/log"
  run "ln -nfs #{shared_path}/tmp #{release_path}"
  run "ln -nfs #{shared_path}/log #{release_path}"
end
