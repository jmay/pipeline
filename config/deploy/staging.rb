set :deploy_to, "/home/asqwer/pipeline"

role :app, "asqwer.com"

ssh_options[:port] = 15554
set :user, "asqwer"

set :scm, :git
set :repository, "git@github.com:jmay/pipeline.git" 
set :branch, "master"
set :deploy_via, :remote_cache
