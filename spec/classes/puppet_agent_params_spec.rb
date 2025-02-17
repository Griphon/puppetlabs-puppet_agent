require 'spec_helper'

describe 'puppet_agent::params' do
  let(:facts) do
    {
      clientversion:   '5.5.3',
      is_pe:           true,
      os: {
        family: 'Debian',
        name: 'Debian',
      },
      servername:      'server',
      # custom fact meant to be used only for tests in this file
      custom_fact__pe_version: '2018.1.3'
    }
  end

  before(:each) do
    Puppet::Parser::Functions.newfunction(:pe_build_version, type: :rvalue, doc: '') do |_args|
      lookupvar('::custom_fact__pe_version')
    end
  end

  context 'collection' do
    # rspec-puppet lets us query the compiled catalog only, so we can only check if any specific resources
    # have been declared. We cannot query for a class' variables, so we cannot query for the collection
    # variable's value. But we can use a workaround by creating a notify resource whose message contains
    # the value and query that instead since it will be added as part of the catalog. post_condition tells
    # rspec-puppet to include this resource only after our class has been compiled, which is what we want.
    let(:notify_title) { "check puppet_agent::params::collection's value" }
    let(:post_condition) do
      <<-NOTIFY_RESOURCE
notify { "#{notify_title}":
  message => "${::puppet_agent::params::collection}"
}
      NOTIFY_RESOURCE
    end

    def sets_collection_to(collection)
      is_expected.to contain_notify(notify_title).with_message(collection)
    end

    context 'pe_version < 2018.1.3' do
      let(:facts) { super().merge(custom_fact__pe_version: '2018.1.2') }

      it { sets_collection_to('PC1') }
    end

    context 'pe_version == 2018.1.3' do
      let(:facts) { super().merge(custom_fact__pe_version: '2018.1.3') }

      it { sets_collection_to('puppet5') }
    end

    context '2018.1.3 < pe_version < 2018.2' do
      let(:facts) { super().merge(custom_fact__pe_version: '2018.1.5') }

      it { sets_collection_to('puppet5') }
    end

    context 'pe_version == 2018.2' do
      let(:facts) { super().merge(custom_fact__pe_version: '2018.2') }

      it { sets_collection_to('puppet6') }
    end

    context '2018.2 <= pe_version < 2021.0' do
      let(:facts) { super().merge(custom_fact__pe_version: '2018.3') }

      it { sets_collection_to('puppet6') }
    end

    context 'pe_version == 2021.0' do
      let(:facts) { super().merge(custom_fact__pe_version: '2021.0') }

      it { sets_collection_to('puppet7') }
    end

    context 'pe_version < 2021.0' do
      let(:facts) { super().merge(custom_fact__pe_version: '2021.1') }

      it { sets_collection_to('puppet7') }
    end
  end
end
