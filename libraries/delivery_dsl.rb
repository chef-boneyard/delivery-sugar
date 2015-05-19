module DeliverySugar
  module Delivery
    def environment_for_current_stage(node)
      stage = node['delivery']['change']['stage']

      if stage == 'acceptance'
        get_acceptance_environment(node)
      else
        stage
      end
    end
    module_function :environment_for_current_stage

    def get_acceptance_environment(node)
      change = node['delivery']['change']
      enterprise = change['enterprise']
      organization = change['organization']
      project = change['project']
      pipeline = change['pipeline']
      "acceptance-#{enterprise}-#{organization}-#{project}-#{pipeline}"
    end
    module_function :get_acceptance_environment
  end

  module DSL
    def delivery_environment
      DeliverySugar::Delivery.environment_for_current_stage(node)
    end

    def get_acceptance_environment
      DeliverySugar::Delivery.get_acceptance_environment(node)
    end
  end
end
