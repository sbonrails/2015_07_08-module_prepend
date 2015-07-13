require 'active_support'

module MethodJournal
  extend ActiveSupport::Concern


  included do |base|
    # Create a nested MethodJournalLayer module and prepend it.
    # This will be used to contain the wrapper methods.
    base.class_eval <<-EOS
      module MethodJournalLayer
      end

      prepend MethodJournalLayer
    EOS
  end


  module ClassMethods
    def journal_method(method_name)
      signature = method_signature(instance_method(method_name))

      # Define the wrapper method in the prepended module; we can then call the original method with `super`.
      # This is the Ruby 2 alternative to alias_method_chain.
      self::MethodJournalLayer.class_eval <<-EOS
        def #{method_name}(#{signature})
          method_journal_wrapper(#{method_name.inspect}, #{signature}) do
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

  def method_journal_wrapper(method_name, *args)
    begin
      puts "\n\n******** #{method_name}(#{args.inspect[1...-1]}) called ********"
      result = yield
      puts "=======> returned #{result.inspect}\n\n"
      result
    rescue => ex
      puts "=======> raised #{ex.class.name}: #{ex.message.inspect}\n\n"
      raise
    end
  end
end
