require 'rake'
require 'rspec/core/rake_task'

task :default => [:help]

desc "Clone the repository"
task :reprepro do
  sh "reprepro -b packages/apt update"
  sh "reprepro -b packages/apt export"
end

desc "Build standalone installer archive"
task :build_standalone_installer => [:reprepro, :spec_prep, :spec_standalone] do
  sh "tar cvzfh ../georchestra.tar.gz README.md packages --exclude-from .gitignore --exclude .git --exclude packages/apt/conf --exclude packages/apt/lists --exclude packages/apt/db -C spec/fixtures modules/ --exclude modules/georchestra/spec/fixtures/modules --exclude modules/georchestra/packages"
end

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end
