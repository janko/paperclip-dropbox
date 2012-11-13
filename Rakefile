#!/usr/bin/env rake
require "bundler/gem_tasks"
Bundler.setup

load "paperclip/dropbox/tasks.rake"

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task default: :spec
