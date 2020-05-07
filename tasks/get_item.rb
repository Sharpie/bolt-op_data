#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'open3'
require 'rubygems'

require 'jmespath'

require_relative '../../ruby_task_helper/files/task_helper.rb'

# Retrieve data from 1password
#
# This task wraps `op`, the 1password CLI, to retrieve a single
# item from a vault in an account. The task expects credentials
# for the account to be set in the appropriate `OP_SESSION_*`
# credential. The ability to use JMESPath expressions to select
# or re-shape data is also included.
#
# @see https://support.1password.com/command-line-getting-started/
# @see https://support.1password.com/command-line/#appendix-session-management
# @see https://jmespath.org/tutorial.html
class OpDataGetItem < TaskHelper
  VERSION = '0.2.0'.freeze

  # @return [String] path to the 1password CLI binary.
  # @return [nil] when no 1password CLI is present.
  #
  # @see #connect_1password
  attr_reader :op_cli

  def task(account:, id:, select: nil, vault: nil, **_opts)
    # Store parameters for use in error messages.
    @account = account
    @id = id
    @select = select
    @vault = vault

    connect_1password(account)

    data = if select.nil?
             get_item(id, vault)
           else
             select_value(get_item(id, vault), select)
           end

    {value: data}
  end

  # Find the 1password CLI and check configuration
  #
  # This method locates the 1password CLI on the `$PATH` and ensures
  # that account credentials have been set in the environment.
  #
  # @param account [String] the name or alias of the 1password account to
  #   fetch data from.
  #
  # @raise [TaskHelper::Error] if the `op` CLI cannot be found or credentials
  #   for the `account` are not set in the environment.
  #
  # @return [void]
  def connect_1password(account)
    if Gem.win_platform?
      @op_cli, have_op = Open3.capture2('where.exe', 'op.exe')
    else
      @op_cli, have_op = Open3.capture2('/bin/sh', '-c', 'command -v op')
    end

    if have_op.success?
      @op_cli.chomp!
    else
      raise TaskHelper::Error.new('Could not find the `op` command. Check the package is installed and the $PATH is configured: https://support.1password.com/command-line-getting-started/',
                                  'op_data/cli-missing',
                                  debug: ENV['PATH'])
    end

    credential = resolve_credential(account)
    unless ENV.key?(credential)
      raise TaskHelper::Error.new('No credentials in environment variable %{env_var}. Did you run `op signin %{account}` and export the result?' %
                                    {account: account,
                                     env_var: credential},
                                  'op_data/credential-missing')
    end
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

  # Retrieve item data from 1password
  #
  # This method uses the `op` CLI to retrieve an item from
  # 1password vaults.
  #
  # @param id [String] the name or UUID of the item to retrieve.
  # @param vault [String, nil] the name or UUID of the vault to
  #   look for the item in (optional).
  #
  # @raise [TaskHelper::Error] if execution of `op` returns an
  #   error.
  #
  # @return [Hash] the result of parsing the JSON representation
  #   of the item.
  def get_item(id, vault = nil)
    cmdline = [op_cli, 'get', 'item', id]
    cmdline.concat(['--vault', vault]) unless vault.nil?

    # TODO: `op get item` makes network calls. Should we
    #   have a defensive timeout here?
    stdout, stderr, status = Open3.capture3(*cmdline)

    if status.success?
      JSON.parse(stdout)
    else
      # The first "[LOG]" line often has details of what went wrong.
      err_msg = stderr.lines.find { |l| l.start_with?('[LOG]') }
      err_msg.chomp! unless err_msg.nil?

      raise TaskHelper::Error.new('`op get item` exited with error code %{code}: %{msg}' %
                                    {code: status.exitstatus,
                                     msg: err_msg},
                                  'op_data/get-item-failed',
                                  debug: stderr)
    end
  end

  # Select a value from a nested data structure
  #
  # This function takes a data structure and a string containing a JMESPath
  # expression, and fetches the value at the path.
  #
  # @param data [Hash, Array] a nested structure of Hashes and Arrays.
  # @param path [String] a JMESPath expression.
  #
  # @raise [TaskHelper::Error] if an error occurs while selecting data.
  #
  # @return [Object] The selected value.
  #
  # @see https://jmespath.org/tutorial.html
  def select_value(data, path)
    value = JMESPath.search(path, data)

    if value.nil?
      raise KeyError, 'no value found at path'
    else
      value
    end
  rescue StandardError => e
    errstring = if @vault.nil?
                  'Error while selecting %{path} from %{id} in %{account}: %{msg} (%{errclass})'
                else
                  'Error while selecting %{path} from %{id} in %{vault} in %{account}: %{msg} (%{errclass})'
                end

    raise TaskHelper::Error.new(errstring %
                                  {path: path,
                                   id: @id,
                                   account: @account,
                                   vault: @vault,
                                   msg: e.message,
                                   errclass: e.class.name},
                                'op_data/select-failed')
  end
end

OpDataGetItem.run if $PROGRAM_NAME == __FILE__
