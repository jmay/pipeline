set :deploy_to, "/home/numbrary/pipeline"

role :app, "numbrary.com"
set :user, "numbrary"

set :scm, :git
set :repository, "git@github.com:jmay/pipeline.git" 
set :branch, "master"
set :deploy_via, :remote_cache
