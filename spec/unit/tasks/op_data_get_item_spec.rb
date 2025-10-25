require 'spec_helper'
require 'open3'
require 'rubygems'

require_relative '../../../tasks/get_item'

describe OpDataGetItem do
  subject(:task) { described_class.new }

  describe '#connect_1password' do
    let(:status) { instance_double(Process::Status) }

    before(:each) do
      allow(ENV).to receive(:key?).with('OP_SESSION_my').and_return(true)
      allow(status).to receive(:success?).and_return(true)
      allow(Open3).to receive(:capture2).and_return(['/foo/bar/op',
                                                     status])
    end

    it 'stores the path to `op`' do
      task.connect_1password('my.1password.com')

      expect(task.op_cli).to eq('/foo/bar/op')
    end

    it 'raises an error when the `op` CLI is missing' do
      allow(status).to receive(:success?).and_return(false)

      expect { task.connect_1password('my.1password.com') }.to \
        raise_error(TaskHelper::Error, /Could not find the `op` command/)
    end
  end

  describe '#get_item' do
    let(:status) { instance_double(Process::Status) }

    before(:each) do
      allow(task).to receive(:op_cli).and_return('/usr/local/bin/op')
      allow(status).to receive(:success?).and_return(true)
      allow(Open3).to receive(:capture3).and_return(['{"hello": "world"}',
                                                     '',
                                                     status])
    end

    it 'returns a Hash when `op get item` succeeds' do
      expect(task.get_item('foo')).to eq({'hello' => 'world'})
    end

    it 'raises an error when `op get item` fails' do
      allow(status).to receive(:success?).and_return(false)
      allow(status).to receive(:exitstatus).and_return(42)

      expect { task.get_item('foo') }.to \
        raise_error(TaskHelper::Error, /exited with error code 42/)
    end
  end

  describe '#select_value' do
    let(:data) do
      {'one' => 'hello',
       'two' => [{'name' => 'world'},
                 {'name' => 'foo'}]}
    end

    it 'uses dotted paths to pull nested data' do
      expect(task.select_value(data, 'two[0].name')).to eq('world')
    end

    it 'raises an exception when nil is returned' do
      expect { task.select_value(data, 'three[0].foo') }.to \
        raise_error(TaskHelper::Error, /no value found at path/)
    end

    it 'raises an exception if the JMESPath expression is invalid' do
      expect { task.select_value(data, '.foo') }.to \
        raise_error(TaskHelper::Error, /unexpected token dot/)
    end
  end
end
