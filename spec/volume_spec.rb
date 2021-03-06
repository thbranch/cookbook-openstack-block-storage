# encoding: UTF-8
#
# Cookbook Name:: openstack-block-storage

require_relative 'spec_helper'

describe 'openstack-block-storage::volume' do
  describe 'ubuntu' do
    let(:runner) { ChefSpec::SoloRunner.new(UBUNTU_OPTS) }
    let(:node) { runner.node }
    let(:chef_run) { runner.converge(described_recipe) }

    include_context 'block-storage-stubs'
    include_examples 'common-logging'
    include_examples 'creates_cinder_conf', 'service[cinder-volume]', 'cinder', 'cinder'

    it 'upgrades cinder volume packages' do
      expect(chef_run).to upgrade_package 'cinder-volume'
    end

    it 'upgrades qemu utils package' do
      expect(chef_run).to upgrade_package 'qemu-utils'
    end

    it 'starts cinder volume' do
      expect(chef_run).to start_service 'cinder-volume'
    end

    it 'starts cinder volume on boot' do
      expect(chef_run).to enable_service 'cinder-volume'
    end

    it 'starts iscsi target on boot' do
      expect(chef_run).to enable_service 'tgt'
    end

    it 'upgrades mysql python packages by default' do
      expect(chef_run).to upgrade_package 'python-mysqldb'
    end

    it 'upgrades postgresql python packages if explicitly told' do
      node.set['openstack']['db']['block-storage']['service_type'] = 'postgresql'

      expect(chef_run).to upgrade_package 'python-psycopg2'
      expect(chef_run).not_to upgrade_package 'python-mysqldb'
    end

    it 'upgrades cinder iscsi package' do
      expect(chef_run).to upgrade_package 'tgt'
    end

    describe 'targets.conf' do
      let(:file) { chef_run.template('/etc/tgt/targets.conf') }

      it 'should create the targets.conf' do
        expect(chef_run).to create_template(file.name).with(
          mode: 0600
        )
      end

      it 'notifies iscsi restart' do
        expect(file).to notify('service[iscsitarget]').to(:restart)
      end

      it 'has ubuntu include' do
        node.set['openstack']['block-storage']['volume']['volumes_dir'] = 'volumes_dir_value'

        expect(chef_run).to render_file(file.name).with_content('include /etc/tgt/conf.d/*.conf')
        expect(chef_run).not_to render_file(file.name).with_content('include volumes_dir_value/*')
      end
    end
  end
end
