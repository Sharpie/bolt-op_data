#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'

require_relative '../../ruby_task_helper/files/task_helper.rb'

class OpDataGetItem < TaskHelper
  def task(account:, id:, select: nil, vault: nil, **opts)
    connect_1password(account)

    data = if select.nil?
             get_item(id, vault)
           else
             select_value(get_item(id, vault), select)
           end

    { value: data }
  end

  def connect_1password(account)
    @op_cli, have_op = Open3.capture2('/bin/sh', '-c', 'command -v op')

    if have_op.success?
      @op_cli.chomp!
    else
      # TODO: Return an error because the op CLI is missing
    end

    credential = resolve_credential(account)
    # TODO: Return an error if ENV[credential] is unset
  end

  # Convert an account name to the name of a 1password credential
  #
  # This method takes a 1password account name in the form of a subdomain
  # or alias and returns the environment variable name that the `op` CLI
  # will expect to find a login token in.
  #
  # @param account [String] The subdomain or alias of a 1password account
  #
  # @return [String] The name of an environment variable where a login
  #   token for the account will be stored.
  def resolve_credential(account)
    name = account.dup
    # Trim 1password.com from the end of the account name
    name.sub!(/\.1password\.com\Z/, '')
    name.tr!('-', '_')

    "OP_SESSION_#{name}"
  end

  def get_item(id, vault = nil)
    cmdline = [@op_cli, 'get', 'item', id]
    cmdline.concat(['--vault', vault]) unless vault.nil?

    stdout, stderr, status = Open3.capture3(*cmdline)

    if status.success?
      JSON.parse(stdout)
    else
      raise TaskHelper::Error.new("'op get item' exited with error code: %{code}" %
                                    { code: status.exitstatus },
                                  'op_data::get_item/get-item-failed',
                                  debug: stderr)
    end
  end

  # Select a value from a nested data structure
  #
  # This function takes a data structure and a string containing a dotted path,
  # such as "details.password", and fetches the value at the path.
  #
  # @param data [Hash, Array] A nested structure of Hashes and Arrays.
  # @param path [String] A dot-delimited path that identifies a value inside
  #   a nested structure of Hashes and Arrays.
  #
  # @return [Object] The selected value.
  def select_value(data, path)
    value = data.dig(*path_to_dig(path))

    if value.nil?
      # TODO: Raise error.
    else
      value
    end
  end

  # Convert a dotted path to arguments for dig
  #
  # This function takes a string containing a dotted path, such as
  # "foo.bar" and produces an argument vector for Ruby's `dig` function.
  #
  # @param path [String] A dot-delimited path that identifies a value inside
  #   a nested structure of Hashes and Arrays.
  #
  # @return [Array<String, Integer>] An argument list of string indices for
  #   Hashes and integer indices for Arrays that can be passed to the
  #   Ruby `dig` function.
  def path_to_dig(path)
    path.split('.').map do |e|
      case e
      when /\d+/
        # Strings of integers are interpreted as array indices
        Integer(e)
      else
        e
      end
    end
  end
end

OpDataGetItem.run if $PROGRAM_NAME == __FILE__
