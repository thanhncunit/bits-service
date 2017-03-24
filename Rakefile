require 'rake'
require 'rspec/core/rake_task'
require 'rake/clean'

task default: ['spec:all']

namespace :spec do
  desc 'Run all specs'
  task all: [:rubocop_autocorrect, :unit, :integration]

  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*_spec.rb'
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*_spec.rb'
  end
end

desc 'Run rubocop with --auto-correct'
task :rubocop_autocorrect do
  require 'rubocop'
  cli = RuboCop::CLI.new
  exit_code = cli.run(%w(--auto-correct))
  exit(exit_code) if exit_code != 0
end

namespace :docs do
  SOURCE_FILES = FileList['docs/*.txt']
  CLEAN.include SOURCE_FILES.pathmap('%d/%n.png')

  SOURCE_FILES.each do |src|
    target = src.pathmap('%d/%n.png')
    desc "Render #{target} from #{src}"
    file target do
      `docs/websequencediagram #{src} #{target}`
      warn "#{src} rendered to #{target}"
    end
  end
end
