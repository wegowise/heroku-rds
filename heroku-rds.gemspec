# -*- encoding: utf-8 -*-
require 'rubygems' unless Object.const_defined?(:Gem)

Gem::Specification.new do |s|
  s.name = "heroku-rds"
  s.version = '0.5.0'
  s.authors = ["Jonathan Dance"]
  s.email = "rubygems@wuputah.com"
  s.homepage = "http://github.com/wegowise/heroku-rds"
  s.summary = "Heroku plugin to aid working with RDS databases"
  s.description = "Heroku plugin to aid working with RDS databases"
  s.required_rubygems_version = ">= 1.3.6"
  s.add_dependency 'heroku', '~> 2.0'
  s.add_dependency 'fog', '>= 0.7.0'
  s.files = Dir.glob('lib/**/*.rb') + %w[README.md .gemspec init.rb]
  s.extra_rdoc_files = ["README.md", "LICENSE.txt"]
  s.license = 'MIT'
end
