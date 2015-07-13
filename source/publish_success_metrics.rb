require 'active_support'
require 'invoca/metrics'

module PublishSuccessMetrics
  include Invoca::Metrics::Source
  extend ActiveSupport::Concern


  included do |base|
    # Create a nested SuccessMetrics module and prepend it.
    # This will be used to contain the wrapper methods.
    base.class_eval <<-EOS
      module SuccessMetrics
      end

      prepend SuccessMetrics
    EOS
  end


  module ClassMethods
    def success_metric_prefix(metric_prefix)
      @success_metric_prefix = metric_prefix
    end

    def publish_success_metric(method_name)
      signature = method_signature(instance_method(method_name))

      # Define the wrapper method in the prepended module; we can then call the original method with `super`.
      # This is the Ruby 2 alternative to alias_method_chain.
      self::SuccessMetrics.class_eval <<-EOS
        def #{method_name}(#{signature})
          publish_success_metric_wrapper(#{@success_metric_prefix.inspect}, #{method_name.inspect}) do
            super
          end
        end
      EOS

      method_name # return our argument so this macro can be chained with other decorators
    end


  private

    def method_signature(method)
      method.parameters.map do |arg_type, arg_name|
        arg_type == :req or raise "unexpected arg type #{arg_type.inspect}"
        arg_name.to_s
      end.join(', ')
    end

  end

  def publish_success_metric_wrapper(*metric_names)
    metric_name = metric_names.compact.join('.')
    begin
      result = yield
      metrics.increment("#{metric_name}.success")
      result
    rescue
      metrics.increment("#{metric_name}.failure")
      raise
    end
  end
end
