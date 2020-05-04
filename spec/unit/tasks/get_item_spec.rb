require 'spec_helper'
require 'open3'

require_relative '../../../tasks/get_item'

describe OpDataGetItem do
  describe '#connect_1password' do
    let(:status) { double(Process::Status) }
    before(:each) do
      allow(ENV).to receive(:key?).with('OP_SESSION_my').and_return(true)
      allow(status).to receive(:success?).and_return(true)
      allow(Open3).to receive(:capture2).and_return(['/foo/bar/op',
                                                     status])
    end

    it 'stores the path to `op`' do
      subject.connect_1password('my.1password.com')

      expect(subject.op_cli).to eq('/foo/bar/op')
    end

    it 'raises an error when the `op` CLI is missing' do
      allow(status).to receive(:success?).and_return(false)

      expect { subject.connect_1password('my.1password.com') }.to \
        raise_error(TaskHelper::Error, /Could not find the `op` command/)
    end

    it 'raises an error when account credentials are not set' do
      allow(ENV).to receive(:key?).with('OP_SESSION_missing_account').and_return(false)

      expect { subject.connect_1password('missing-account.1password.com') }.to \
        raise_error(TaskHelper::Error, /No credentials in environment variable OP_SESSION_missing_account/)
    end
  end

  describe '#get_item' do
    let(:status) { double(Process::Status) }
    before(:each) do
      allow(subject).to receive(:op_cli).and_return('/usr/local/bin/op')
      allow(status).to receive(:success?).and_return(true)
      allow(Open3).to receive(:capture3).and_return(['{"hello": "world"}',
                                                     '',
                                                     status])
    end

    it 'returns a Hash when `op get item` succeeds' do
      expect(subject.get_item('foo')).to eq({"hello" => "world"})
    end

    it 'raises an error when `op get item` fails' do
      allow(status).to receive(:success?).and_return(false)
      allow(status).to receive(:exitstatus).and_return(42)

      expect { subject.get_item('foo') }.to \
        raise_error(TaskHelper::Error, /exited with error code 42/)
    end
  end

  describe '#select_value' do
    let(:data) { {'one' => 'hello',
                  'two' => [{'name' => 'world'},
                            {'name' => 'foo'}]} }

    it 'uses dotted paths to pull nested data' do
      expect(subject.select_value(data, 'two.0.name')).to eq('world')
    end

    it 'raises an exception when nil is returned' do
      expect { subject.select_value(data, 'three.0.foo') }.to \
        raise_error(TaskHelper::Error, /no value found at path/)
    end

    it 'raises an exception if the path includes a non-diggable value' do
      expect { subject.select_value(data, 'one.boom') }.to \
        raise_error(TaskHelper::Error, /String does not have #dig method/)
    end
  end

  describe '#path_to_dig' do
    it 'splits dotted paths to an array of strings' do
      input = 'one.two three.four'

      expect(subject.path_to_dig(input)).to eq(['one',
                                                'two three',
                                                'four'])
    end

    it 'converts strings of digits to integers' do
      input = '0.first.1.second'

      expect(subject.path_to_dig(input)).to eq([0,
                                                'first',
                                                1,
                                                'second'])
    end
  end
end
