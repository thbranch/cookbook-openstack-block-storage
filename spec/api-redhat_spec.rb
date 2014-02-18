# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::api' do
  before { block_storage_stubs }
  describe 'redhat' do
    before do
      @chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      @chef_run.converge 'openstack-block-storage::api'
    end

    it 'installs cinder api packages' do
      expect(@chef_run).to upgrade_package 'python-cinderclient'
    end

    it 'installs mysql python packages by default' do
      expect(@chef_run).to upgrade_package 'MySQL-python'
    end

    it 'installs db2 python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      node = chef_run.node
      node.set['openstack']['db']['block-storage']['service_type'] = 'db2'
      chef_run.converge 'openstack-block-storage::api'

      ['db2-odbc', 'python-ibm-db', 'python-ibm-db-sa'].each do |pkg|
        expect(chef_run).to upgrade_package pkg
      end
    end

    it 'installs postgresql python packages if explicitly told' do
      chef_run = ::ChefSpec::Runner.new ::REDHAT_OPTS
      node = chef_run.node
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'
      chef_run.converge 'openstack-block-storage::api'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'MySQL-python'
    end

    it 'starts cinder api on boot' do
      expect(@chef_run).to enable_service 'openstack-cinder-api'
    end
  end
end
