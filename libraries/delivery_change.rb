module DeliverySugar
  class Change
    attr_reader :enterprise, :organization, :project, :pipeline,
      :stage
    def initialize(node)
      _change = node['delivery']['change']
      @enterprise = _change['enterprise']
      @organization = _change['organization']
      @project = _change['project']
      @pipeline = _change['pipeline']
      @stage = _change['stage']
    end

    def acceptance_environment
      "acceptance-#{@enterprise}-#{@organization}-#{@project}-#{@pipeline}"
    end

    def environment_for_current_stage
      @stage == 'acceptance' ? acceptance_environment : @stage
    end
  end
end
