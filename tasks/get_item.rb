#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'

require_relative '../../ruby_task_helper/files/task_helper.rb'

class OpDataGetItem < TaskHelper
  def task(account:, id:, extract: nil, vault: nil, **opts)
    { value: 'hello, world!' }
  end
end

OpDataGetItem.run if $PROGRAM_NAME == __FILE__
