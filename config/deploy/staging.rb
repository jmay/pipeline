set :deploy_to, "/home/asqwer/pipeline"

role :app, "asqwer.com"

ssh_options[:port] = 15554
set :user, "asqwer"

namespace :deploy do
  %w(start stop restart).each do |action| 
     desc "#{action} the Thin processes"  
     task action.to_sym do
       find_and_execute_task("thin:#{action}")
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
