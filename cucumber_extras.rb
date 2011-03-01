if recipe_list.include? 'cucumber'
  say_recipe 'Cucumber extras'

  # pop a browser window in cucumber and other tasks
  gem 'launchy', :group => :test

  gem 'database_cleaner', :group => :test

  gem 'factory_girl_rails', :group => [:development, :test]
end
