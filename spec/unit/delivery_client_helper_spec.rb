require 'spec_helper'

describe Chef_Delivery::ClientHelper do
  describe '.chef_server' do
    let(:cs_inst) { instance_double('DeliverySugar::ChefServer') }

    it 'creates a new ChefServer object' do
      expect(DeliverySugar::ChefServer).to receive(:new).and_return(cs_inst)
      described_class.send(:chef_server)
      expect(described_class.chef_server).to be(cs_inst)
    end
  end

  describe '.leave_client_mode_as_delivery' do
    it 'unloads the chef server config' do
      expect(described_class).to receive_message_chain(:chef_server, :send)
        .with(:unload_server_config)
      expect(described_class).to receive(:print_deprecation_warning)
      described_class.leave_client_mode_as_delivery
    end
  end

  describe '.enter_client_mode_as_delivery' do
    it 'loads the chef server config' do
      expect(described_class).to receive_message_chain(:chef_server, :send)
        .with(:load_server_config)
      expect(described_class).to receive(:print_deprecation_warning)
      described_class.enter_client_mode_as_delivery
    end
  end
end
