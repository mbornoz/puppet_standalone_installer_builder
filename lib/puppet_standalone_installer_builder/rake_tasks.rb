require 'rake'
require 'rspec/core/rake_task'
require 'yaml'

task :default => [:help]

desc 'Check if working directory is clean'
task :check_git_status do
  fail "You have unstaged changes." unless system("git diff --exit-code")
  fail "You have changes that are staged but not committed." unless system("git diff --cached --exit-code")
  fail "You have untracked files." unless system("git ls-files --other --exclude-standard --directory")
end

desc 'Check if all dependency version is explicitely set'
task :check_deps_version do
  fixtures = YAML.load_file('.fixtures.yml')
  fixtures['fixtures']['repositories'].select { |k, v| fail "You must explicitely set ref for module #{k} in .fixtures.yml for a reproductible build." unless v.is_a?(Hash) and v.has_key?('ref') and !v['ref'].nil? }
end

desc 'Check tag'
task :check_tag do
  fail "You must tag the current commit for a reproductible build." unless !`git tag --contains $(git rev-parse HEAD)`.empty?
end

desc "Clone the repository"
task :reprepro do
  sh "reprepro -b packages/apt update"
  sh "reprepro -b packages/apt export"
end

desc "Build the tarball"
task :build_tarball => [:check_git_status, :check_deps_version, :check_tag, :reprepro, :spec_prep, :spec_standalone] do
  profile = File.basename(Dir.pwd)[/^puppet-(.*)$/, 1]
  tags = `git tag --contains $(git rev-parse HEAD)`.split("\n")
  version = tags[0] unless tags.length > 1
  tarball = "../#{profile}-#{version}.tar.gz"
  apt_dir = 'packages/apt'

  sh "tar cvzfh #{tarball} README.md packages --exclude-from .gitignore --exclude .git --exclude #{apt_dir}/conf --exclude #{apt_dir}/lists --exclude #{apt_dir}/db -C spec/fixtures modules/ --exclude modules/#{profile}/spec/fixtures/modules --exclude modules/#{profile}/packages"

  puts "Tarball of module #{profile} built in #{tarball}."
end

desc "Build standalone installer archive"
task :build_standalone_installer => [:build_tarball, :spec_clean]

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end
