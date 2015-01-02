require_relative '../spec_helper_acceptance'
require_relative '../support/shared_acceptance_specs'


describe 'ora_listener' do

  # before do
  #   # Stop the listener for the tests
  #   on master, '/sbin/service iptables stop' # Make sure no iptables to hinder our test
  #   on master, "su - oracle -c 'export ORACLE_SID=test;export ORAENV_ASK=NO;. oraenv;lsnrctl stop'"
  # end


  let(:ensure_running) {<<-EOS}
    ora_listener{'test':
      ensure => 'running',
    }
  EOS

  let(:ensure_stopped) {<<-EOS}
    ora_listener{'test':
      ensure => 'stopped',
    }
  EOS


  context "listener is stopped" do

    it "is still stopped after ensure => stopped" do
      apply_manifest(ensure_stopped, :expect_changes => false)
    end

    it "is running after ensure => running" do
      apply_manifest(ensure_running, :expect_changes => true)
    end

  end

  context "listener is started" do

    it "is still running after ensure => running" do
      apply_manifest(ensure_running, :expect_changes => false)
    end

    it "is stopped after ensure => stopped" do
      apply_manifest(ensure_stopped, :expect_changes => true)
    end


  end

end
