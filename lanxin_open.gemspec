# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lanxin_open/version'

Gem::Specification.new do |spec|
  spec.name          = "lanxin_open"
  spec.version       = LanxinOpen::VERSION
  spec.authors       = ["wangdean"]
  spec.email         = ["bjkjdxwda@126.com","wangdean@comisys.net"]
  spec.summary       = %q{Lanxin Openplatform ruby sdk.}
  spec.description   = %q{Lanxin is Real-time communication application for enterprise internal communicate,with full client support,including Android, iOS, Windows,Mac,Web etc.The Openplatform give the thirdpart company provide service through Lanxin.More information please refer to http://lanxin.cn.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
