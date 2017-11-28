# frozen_string_literal: true

require './app'
require 'puma'

Encoding.default_external = Encoding::UTF_8

set :logging, false
run BitsService::App
