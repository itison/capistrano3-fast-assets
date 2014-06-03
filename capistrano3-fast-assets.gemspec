lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "capistrano3-fast-assets"
  gem.version       = '0.0.1'
  gem.authors       = ["Gavin Montague"]
  gem.email         = ["gavin.montague@itison.com"]
  gem.description   = "Selectively compile Rails assets when deploying"
  gem.summary       = "Selectively compile Rails assets when deploying"
  gem.homepage      = "https://github.com/tablexi/capistrano3-unicorn"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'capistrano', '>= 3.1.0'
end
