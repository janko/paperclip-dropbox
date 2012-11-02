#!/usr/bin/env rake
require "bundler/gem_tasks"
require "paperclip/dropbox/rake"
import 'lib/paperclip/dropbox/tasks/authorize.rake'

Bundler.setup

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec
