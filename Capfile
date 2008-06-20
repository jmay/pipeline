load "deploy"

# require 'capistrano/ext/multistage'
# set :stages, %w(staging production)
# set :default_stage, "production"


set :deploy_to, "/home/asqwer/pipeline"

# role :web, "asqwer.com"
role :app, "asqwer.com"
# role :db,  "asqwer.com"

ssh_options[:port] = 15554
set :user, "asqwer"

set :scm, :git
set :repository, "git@github.com:jmay/pipeline.git"
set :branch, "master"
set :deploy_via, :remote_cache
