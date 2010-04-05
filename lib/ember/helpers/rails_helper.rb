module ActionView
  module TemplateHandlers
    #
    # @example Setting processing options for Ember
    #
    #   ActionView::TemplateHandlers::Ember.options = {
    #     :unindent => true,
    #     :shorthand => true,
    #     :infer_end => true
    #   }
    #
    # @see Ember::Template
    #
    class Ember < TemplateHandler
      include Compilable

      @@options = {}
      cattr_accessor :options

      def compile(template)
        options = @@options.merge(:result_variable => :@output_buffer,
                                  :source_file => template.filename)
        ember = ::Ember::Template.new(template.source, options)
        "__in_erb_template = true; #{ember.program}"
      end
    end
  end

  ember_handler = TemplateHandlers::Ember
  Template.register_default_template_handler :erb, ember_handler
  Template.register_template_handler :rhtml, ember_handler
end
