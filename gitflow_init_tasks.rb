say_recipe 'Create git-flow init:* tasks'

create_file 'lib/tasks/init_gitflow.rake' do
  <<-'RAKE'.gsub(/^ {4}/, '')
    namespace :init do
      task 'gitflow_init' do
        preconditions = [
          %{git config --get gitflow.branch.master >/dev/null 2>&1},
          %{git config --get gitflow.branch.develop >/dev/null 2>&1},
          %{git config --get gitflow.prefix.feature >/dev/null 2>&1},
          %{git config --get gitflow.prefix.release >/dev/null 2>&1},
          %{git config --get gitflow.prefix.hotfix >/dev/null 2>&1},
          %{git config --get gitflow.prefix.support >/dev/null 2>&1},
          %{git config --get gitflow.prefix.versiontag >/dev/null 2>&1}
        ]
        sh preconditions.join(" && ") do |ok, res|
          if ok
            puts ">>>> git-flow has already been initialized, so skipping"
          else
            puts "===> Initializing git-flow with defaults..."
            sh %{git flow init -d}
          end
        end
      end
    end

    unless Rake::Task.task_defined?("init")
      desc "Initializes the rails environment for development"
      task :init do ; end
    end

    # Add namespaced tasks to default :init task
    Rake::Task["init"].enhance ["init:gitflow_init"]
  RAKE
end
