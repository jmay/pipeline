set :deploy_to, "/home/numbrary/pipeline"

role :app, "numbrary.com"
set :user, "numbrary"
set :group, "numbrary"

set :application, "batch"

set :thin_max_instances, 2
set :service_list, "`svcs -H -o FMRI svc:network/thin/#{application}-production`"

namespace :deploy do
  %w(start stop restart).each do |action| 
     desc "#{action} the Thin processes"  
     task action.to_sym, :roles => :app do
       # find_and_execute_task("thin:#{action}")
       find_and_execute_task("accelerator:smf_#{action}")
    end
  end 
end

namespace :thin do  
  %w(start stop restart).each do |action| 
  desc "#{action} the app's Thin Cluster"  
    task action.to_sym, :roles => :app do  
      run "thin #{action} -c #{current_path} -C #{shared_path}/config/thin.yml" 
    end
  end
end

namespace :accelerator do
  desc "Stops all Thin servers, disable until next reboot"
  task :smf_stop, :roles => :app do
    sudo "svcadm disable -t #{service_list}"
  end

  desc "Starts all Thin servers"
  task :smf_start, :roles => :app do
    sudo "svcadm enable -r #{service_list}"
  end

  desc "Restarts the Thin servers"
  task :smf_restart do
    smf_stop
    smf_start
  end

  desc "Shows all Services"
  task :svcs, :roles => :app do
    run "svcs -a" do |ch, st, data|
      puts data
    end
  end
end

desc "Create and deploy Thin SMF config"
task :create_thin_smf, :roles => :app do
  service_name = application
  working_directory = current_path
  template = File.read("config/accelerator/thin_solaris_smf.erb.xml")
  buffer = ERB.new(template).result(binding)
  put buffer, "#{shared_path}/config/#{application}-thin-smf.xml"
  sudo "svccfg import #{shared_path}/config/#{application}-thin-smf.xml"
end

desc "Delete Thin SMF config"
task :delete_thin_smf, :roles => :app do
  accelerator.smf_stop
  sudo "svccfg delete /network/thin/#{application}-production"
end
