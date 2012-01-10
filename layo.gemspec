require 'base64'

Gem::Specification.new do |s|
  s.name = 'layo'
  s.version = '1.0.0'
  s.summary = 'LOLCODE interpreter written in plain Ruby'
  s.description = <<-EOF
    Layo is a LOLCODE interpreter written in plain Ruby. It tries to conform to
    the LOLCODE 1.2 specification and supports everything described there.
  EOF
  s.required_ruby_version = '>= 1.9.2'
  s.add_development_dependency 'mocha', '~> 0.10.0'

  s.files = `git ls-files`.split("\n")

  s.executables << 'layo'

  s.test_files = s.files.select { |path| path =~ /^spec\/.*_spec\.rb/ }

  s.authors = ['Galymzhan Kozhayev']
  s.email = Base64.decode64("a296aGF5ZXZAZ21haWwuY29t\n")
  s.homepage = 'http://github.com/galymzhan/layo'
end
