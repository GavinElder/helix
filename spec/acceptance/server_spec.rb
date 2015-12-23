require 'spec_helper_acceptance'

describe 'helix::server class' do
  context 'with required parameters only' do
    # Using puppet_apply as a helper
    it 'should work idempotently with no errors' do
      pp = <<-EOS
include helix::server

helix::server_instance { 'server1':
  p4port => '1666',
}

EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes  => true)
    end

    # describe command('/usr/sbin/p4p -V') do
    #   its(:stdout) { should match /Perforce - The Fast Software Configuration Management System/ }
    # end
    #
    # describe port(1668) do
    #   it { should be_listening }
    # end

  end
end
