say_recipe 'guard'

gem 'rb-fsevent', :group => :test, :platforms => :ruby
gem 'growl',      :group => :test

# 0.9 rc needed for rails3, see
# http://opinionated-programmer.com/2011/02/profiling-spork-for-faster-start-up-time/
gem 'spork', '~> 0.9.0.rc', :group => :test

# cli to easily handle events on files modifications
# git version to make guard-spork and guard-ego play nice, see
# https://github.com/guard/guard/pull/34
gem "guard", :git => "git://github.com/guard/guard.git", :group => :test
# the alter ego of Guard and will reload Guard when necessary
gem "guard-ego", :group => :test

if recipe_list.include?('rspec') || recipe_list.include?('cucumber')
  # automatically manage Spork DRb servers
  gem "guard-spork", :group => :test
end

# automatically install/update your gem bundle when needed
gem "guard-bundler", :group => :test

if recipe_list.include? 'rspec'
  # automatically run your RSpec specs when files are modified
  gem "guard-rspec", :group => :test
end

if recipe_list.include? 'cucumber'
  # automatically run Cucumber features when files are modified
  gem "guard-cucumber", :group => :test
end

# automatically reload your browser when ‘view’ files are modified
gem "guard-livereload", :group => :test

create_file 'Guardfile' do
  <<-'GUARDFILE'.gsub(/^ {4}/, '')
    # More info at https://github.com/guard/guard#readme

    guard 'ego' do
      watch('Guardfile')
    end

    guard 'spork' do
      watch('config/application.rb')
      watch('config/environment.rb')
      watch(%r{^config/environments/.*\.rb$})
      watch(%r{^config/initializers/.*\.rb$})
      watch('spec/spec_helper.rb')
    end

    guard 'bundler' do
      watch('Gemfile')
    end

    guard 'rspec', :cli => "--color --format nested --drb" do
      watch(%r{^spec/.+_spec\.rb})
      watch(%r{^lib/(.+)\.rb})     { |m| "spec/lib/#{m[1]}_spec.rb" }
      watch('spec/spec_helper.rb') { "spec" }

      # Rails example
      watch('spec/spec_helper.rb')                       { "spec" }
      watch('config/routes.rb')                          { "spec/routing" }
      watch('app/controllers/application_controller.rb') { "spec/controllers" }
      watch(%r{^spec/.+_spec\.rb})
      watch(%r{^app/(.+)\.rb})                           { |m| "spec/#{m[1]}_spec.rb" }
      watch(%r{^lib/(.+)\.rb})                           { |m| "spec/lib/#{m[1]}_spec.rb" }
      watch(%r{^app/controllers/(.+)_(controller)\.rb})  { |m| ["spec/routing/#{m[1]}_routing_spec.rb", "spec/#{m[2]}s/#{m[1]}_#{m[2]}_spec.rb", "spec/acceptance/#{m[1]}_spec.rb"] }
    end

    guard 'cucumber', :drb => true, :profile => "spork" do
      watch(%r{features/.+\.feature})         { 'features' }
      watch(%r{features/support/.+})          { 'features' }
      watch(%r{features/step_definitions/.+}) { 'features' }
    end
  GUARDFILE
end

after_bundler do
  if recipe_list.include? 'cucumber'
    # Add spork erb opts
    gsub_file "config/cucumber.yml", /^(std_opts = .*wip")$/, '\1' << <<-'OPTS'.gsub(/^ {6}/, '')

      std_opts += " --tags ~@proposed --color"
      spork_opts = "--format rerun --out rerun.txt --strict --tags ~@proposed"
    OPTS

    # Add spork formats
    gsub_file "config/cucumber.yml", /^(rerun: .* ~@wip)$/, '\1 --tags ~@proposed'
    append_to_file "config/cucumber.yml" do
      <<-'YAML'.gsub(/^ {8}/, '')
        spork: <%= spork_opts %> features
      YAML
    end

    # Add spork support for Cucumber
    gsub_file "features/support/env.rb", /^(.+)$/, '  \1'
    gsub_file "features/support/env.rb", /^  (ENV\["RAILS_ENV"\].*)$/,
        <<-'ENV'.gsub(/^ {6}/, '') + '  \1'
      require 'spork'

      Spork.prefork do

    ENV
    gsub_file "features/support/env.rb", /^  (Capybara.default_selector.*)$/,
        ' \1' << <<-'ENV'.gsub(/^ {6}/, '')


      end

      Spork.each_run do
    ENV
    append_to_file "features/support/env.rb" do
      <<-'THEEND'.gsub(/^ {8}/, '')

        end
        # the end :)
      THEEND
    end
  end

  if recipe_list.include? 'rspec'
    # Add spork support for RSpec
    gsub_file "spec/spec_helper.rb", /^/, '  '
    gsub_file "spec/spec_helper.rb", /^  # This file is .*$\n/, ''
    gsub_file "spec/spec_helper.rb", /^  (ENV\["RAILS_ENV"\].*)$/,
        '\1' << <<-'SPEC'.gsub(/^ {6}/, '')


      require 'spork'

      Spork.prefork do
    SPEC
    append_to_file "spec/spec_helper.rb" do
      <<-'SPEC'.gsub(/^ {8}/, '')
        end

        Spork.each_run do
          # This code will be run each time you run your specs
        end
      SPEC
    end
  end
end
