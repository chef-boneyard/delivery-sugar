require 'spec_helper'

describe DeliverySugar::DSL do
  subject do
    Object.new.extend(described_class)
  end

  describe '.changed_cookbooks' do
    it 'gets a list of changed cookbook from the change object' do
      expect(subject).to receive_message_chain(:delivery_change,
                                               :changed_cookbooks)
      subject.changed_cookbooks
    end
  end

  describe '.changed_files' do
    it 'gets a list of changed files from the change object' do
      expect(subject).to receive_message_chain(:delivery_change, :changed_files)
      subject.changed_files
    end
  end

  describe '.delivery_environment' do
    it 'get the current environment from the Change object' do
      expect(subject).to receive_message_chain(:delivery_change,
                                               :environment_for_current_stage)
      subject.delivery_environment
    end
  end

  describe '.get_acceptance_environment' do
    it 'gets the acceptance environment for the pipeline from the change object' do
      expect(subject).to receive_message_chain(:delivery_change,
                                               :acceptance_environment)
      subject.get_acceptance_environment
    end
  end

  describe '.project_slug' do
    it 'gets slug from Change object' do
      expect(subject).to receive_message_chain(:delivery_change, :project_slug)
      subject.project_slug
    end
  end

  describe '.get_project_secrets' do
    it 'gets the secrets from the Change object' do
      expect(subject).to receive_message_chain(:delivery_change,
                                               :project_secrets)
      subject.get_project_secrets
    end
  end
end
