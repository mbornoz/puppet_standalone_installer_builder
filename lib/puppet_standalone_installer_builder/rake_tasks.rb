require 'rake'
require 'rspec/core/rake_task'
require 'yaml'
require 'erb'

task :default => [:help]

desc 'Check if we are not working in master'
task :check_branch do
  fail "You must work in a branch other than master." unless ENV['nocheck'] or ENV['nocheck_branch'] or `git rev-parse --abbrev-ref HEAD`.strip != 'master'
end

desc 'Check if working directory is clean'
task :check_git_status do
  if !ENV['nocheck'] and !ENV['nocheck_git_status']
    fail "You have unstaged changes." unless system("git diff --exit-code")
    fail "You have changes that are staged but not committed." unless system("git diff --cached --exit-code")
    fail "You have untracked files." unless system("git ls-files --other --exclude-standard --directory")
  end
end

desc 'Check if gem version is explicitely set'
task :check_gem_version do
  puts 'TODO: Check if gem version is explicitely set' unless ENV['nocheck'] or ENV['nocheck_gem_version']
end

desc 'Check if all dependency version is explicitely set'
task :check_deps_version do
  if !ENV['nocheck'] and !ENV['nocheck_deps_version']
    fixtures("repositories").each do |remote, opts|
      fail "You must explicitely set a tag or commit ref for module #{remote} in .fixtures.yml for a reproductible build." unless opts.is_a?(Hash) and opts.has_key?('ref') and (!`git ls-remote #{remote} refs/tags/#{opts['ref']}`.empty? or opts['ref'] =~ /^[0-9a-f]{7,40}$/)
    end
    fixtures("forge_modules").each do |remote, opts|
      fail "You must explicitely set a tag or commit ref for module #{remote} in .fixtures.yml for a reproductible build." unless opts.is_a?(Hash) and opts.has_key?('ref')
    end
  end
end

desc 'Check tag'
task :check_tag do
  fail "You must tag the current commit for a reproductible build." unless ENV['nocheck'] or ENV['nocheck_tag'] or !`git tag --contains $(git rev-parse HEAD)`.empty?
end

desc 'Check pre-requirements'
task :build_check => [:check_branch, :check_git_status, :check_gem_version, :check_deps_version, :check_tag]

desc "Clone the repository"
task :reprepro do
  if File.file?('packages/apt/conf/distributions') and File.file?('packages/apt/conf/updates')
    sh "reprepro -b packages/apt update"
    sh "reprepro -b packages/apt export"
  end
end

desc "Build md doc"
task :build_md_doc do
  profile = File.basename(Dir.pwd)[/^puppet-(.*)$/, 1]
  properties = File.file?('.psib.yaml') ?  YAML.load_file('.psib.yaml') : {}
  properties['profile'] ||= profile
  properties['title'] ||= properties['profile']
  tag = `git describe --tags --exact-match`.strip
  version = (tag unless tag.empty?) || 'dev'

  endusermd_template = ERB.new File.new(File.expand_path('../../../templates/ENDUSER.md.erb', __FILE__)).read, nil, "%"
  File.open('spec/fixtures/ENDUSER.md', 'w') { |file| file.write(endusermd_template.result(binding)) }
end

desc "Build pdf doc"
task :build_pdf_doc => [:build_md_doc] do
  properties = File.file?('.psib.yaml') ?  YAML.load_file('.psib.yaml') : {}
  tag = `git describe --tags --exact-match`.strip
  version = (tag unless tag.empty?) || 'dev'
  texdir = File.expand_path('../../../tex', __FILE__)
  File.open(File.join(texdir, 'docversion.tex'), 'w') do |f|
    f.write("\\newcommand{\\docversion}{#{version}}\n")
  end

  # Get forked unoconv
  puts "Forking unoconv"
  `git clone https://github.com/camptocamp/unoconv.git`

  ott = File.expand_path('../../../templates/template_document_v2.2.ott', __FILE__)
  unoconv_cmd= "python3 $(COMMON_DIR)/unoconv/unoconv -f pdf \
	 	-F Client_Name=\"#{properties['title']}\" \
	 	-F Document_Title=\"\" \
	 	-F Document_Last_Version=\"#{version}\" \
		-F Document_Date=\"\" \
	 	--stdout"

  docs = []
  docs << File.expand_path('README.md') if File.file?('README.md')
  docs << File.expand_path('spec/fixtures/ENDUSER.md')

  docs.each do |doc|
    base_doc = doc.gsub(/\.md$/, '')
    pdf_inside = "#{base_doc}_inside.pdf"
    pdf_cover = "#{base_doc}_cover.pdf"

    # Generate inside doc
    pdf = "#{base_doc}.pdf"
    `cd #{texdir} && pandoc -o #{pdf_inside} #{doc} \
    --latex-engine=xelatex  --toc -H "header-includes.tex" \
    -V "lang=en" -V "mainfont=Gotham-Book" -V "documentclass=scrbook" \
    -V "classoption=open=any" -V "fontsize=10pt" -V "papersize=a4"`

    # Generate cover
    `#{unoconv_cmd} -F Document_Type="#{properties['title']}" "#{ott}" | pdftk - cat 1 end output "#{pdf_cover}"`

    # Assemble PDF
    `pdftk A="#{pdf_inside}" B="#{pdf_cover}" cat A1 B A2 output "#{pdf}"`
  end
end

desc "Build the tarball"
task :build_tarball => [:build_check, :reprepro, :spec_prep, :spec_standalone, :build_pdf_doc] do
  profile = File.basename(Dir.pwd)[/^puppet-(.*)$/, 1]
  tag = `git describe --tags --exact-match`.strip
  version = (tag unless tag.empty?) || 'dev'
  tarball = "../#{profile}-installer-#{version}.tar.gz"
  base_path = "#{profile}-installer"
  apt_dir = 'packages/apt'

  properties = File.file?('.psib.yaml') ?  YAML.load_file('.psib.yaml') : {}
  properties['profile'] ||= profile
  properties['title'] ||= properties['profile']
  installsh_template = ERB.new File.new(File.expand_path('../../../templates/install.sh.erb', __FILE__)).read, nil, "%"
  Dir.mkdir('spec/fixtures/bin') unless File.exists?('spec/fixtures/bin')
  File.open('spec/fixtures/bin/install.sh', 'w') { |file| file.write(installsh_template.result(binding)); file.chmod(0755) }

  readme   = 'README.pdf' if File.file?('README.pdf')
  packages = 'packages' if File.exist?('packages')
  examples = 'examples' if File.exist?('examples')

  sh "tar cvzfh #{tarball} --owner=root --group=root #{readme} #{packages} #{examples} --exclude-from .gitignore --exclude .git --exclude #{apt_dir}/conf --exclude #{apt_dir}/lists --exclude #{apt_dir}/db -C spec/fixtures ENDUSER.pdf bin/ manifests/ --exclude manifests/site.pp modules/ --exclude modules/#{profile}/spec/fixtures/modules --exclude modules/#{profile}/packages --transform 's,^,#{base_path}/,'"

  puts "Tarball of module #{profile} built in #{tarball}."
end

desc "Build standalone installer archive"
task :build_standalone_installer => [:build_tarball, :spec_clean]

desc "Display the list of available rake tasks"
task :help do
  system("rake -T")
end
