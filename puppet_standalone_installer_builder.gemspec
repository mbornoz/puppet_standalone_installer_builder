Gem::Specification.new do |gem|
  gem.name          = 'puppet_standalone_installer_builder'
  gem.version       = '0.0.3'
  gem.date          = '2014-06-04'
  gem.summary       = 'Puppet standalone installer builder'
  gem.description   = 'Helps you to build standalone installer for puppet'
  gem.authors       = ['Camptocamp']
  gem.email         = 'info@camptocamp.com'
  gem.homepage      = 'https://github.com/camptocamp/puppet_standalone_installer_builder'
  gem.license       = 'Apache 2.0'

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.require_paths = ['lib']
end
