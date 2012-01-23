# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "i18n_backend_database/version"

Gem::Specification.new do |s|
  s.name = %q{i18n_backend_database_rails3}

  s.authors = ["Dylan Stamat", "Hector Bustillos"]
  s.date = %q{2012-01-23}
  s.description = %q{This is a gem based on the original repo of Dylan Stamat, which add's cool functions to manage i18n}
  s.email = %w{hector.bustillos@crowdint.com}
  s.has_rdoc = false
  s.version     = I18n::Backend::Database::VERSION
  s.homepage    = "https://hecbuma@github.com/hecbuma/i18n_backend_database.git"
  s.summary     = %q{Cool utils and admin for I18n}

  s.rubyforge_project = "compass-bootstrap"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

end
