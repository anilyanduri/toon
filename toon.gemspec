Gem::Specification.new do |s|
  s.name        = 'ruby-toon'
  s.version     = Toon::VERSION rescue '1.0.0'
  s.summary     = 'Token-Oriented Object Notation (TOON) implementation for Ruby'
  s.description = 'A full-featured TOON encoder/decoder with JSON feature parity: streaming, hooks, pretty generate, strict parsing, schema hints, CLI and ActiveSupport integration.'
  s.authors     = ['Anil Yanduri']
  s.email       = ['anilkumaryln@gamil.com']
  s.files       = Dir['lib/**/*.rb'] + ['README.md', 'LICENSE']
  s.homepage    = 'https://github.com/anilyanduri/toon'
  s.license     = 'MIT'
  s.required_ruby_version = '>= 2.7.1'
  s.add_development_dependency 'rspec'
  s.add_dependency 'activesupport', '>= 6.0'
end
