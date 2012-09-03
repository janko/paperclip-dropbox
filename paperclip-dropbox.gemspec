# encoding: utf-8

Gem::Specification.new do |gem|
  gem.name          = "paperclip-dropbox"
  gem.version       = "0.0.2"

  gem.authors       = ["Janko Marohnić"]
  gem.email         = ["janko.marohnic@gmail.com"]
  gem.description   = %q{Extends Paperclip with Dropbox storage.}
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/janko-m/paperclip-dropbox"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "paperclip", "~> 3.1"
  gem.add_dependency "dropbox-sdk", "~> 1.3"

  gem.add_development_dependency "rake", "~> 0.9"
  gem.add_development_dependency "rspec", "~> 2.11"
  gem.add_development_dependency "vcr", "~> 2.2"
  gem.add_development_dependency "fakeweb", "~> 1.3"
  gem.add_development_dependency "activerecord", "~> 3.2"
  gem.add_development_dependency "rack-test", "~> 0.6"
  gem.add_development_dependency "sqlite3", "~> 1.3"
end
