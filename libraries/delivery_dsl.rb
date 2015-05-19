module DeliverySugar
  module DSL
    def delivery_change
      @@delivery_change ||= DeliverySugar::Change.new(node)
    end

    def delivery_environment
      delivery_change.environment_for_current_stage
    end

    def get_acceptance_environment
      delivery_change.acceptance_environment
    end

    def changed_files
      delivery_change.changed_files
    end
  end
end
