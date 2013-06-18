require "abstract_controller"

# Rendering extension
module Middleman

  module Rendering
    extend ::ActiveSupport::Concern

    include ::AbstractController::Rendering
    # include ::AbstractController::Layouts
      # AbstractController::Translation,
      # AbstractController::AssetPaths,

    included do
      ::Tilt.mappings.delete('html') # WTF, Tilt?
      ::Tilt.mappings.delete('csv')
    end

    module ClassMethods
      def abstract; true; end
      alias_method :abstract?, :abstract

      def view_context_class
        @view_context_class ||= begin
          helpers = respond_to?(:_helpers) && _helpers

          Class.new(::Middleman::View) do
            if helpers
              include helpers
            end
          end
        end
      end
    end

    def _normalize_options(options)
      super

      layout = options.delete(:layout) { :default }

      if layout != false
        options[:layout] = "layouts/#{layout}"
      end
    end

    def lookup_context
      @_lookup_context ||= ::Middleman::LookupContext.new(self, details_for_lookup)
    end

    # Add or overwrite a default template extension
    #
    # @param [Hash] extension_map
    # @return [Hash]
    def template_extensions(extension_map=nil)
      @_template_extensions ||= {}
      @_template_extensions.merge!(extension_map) if extension_map
      @_template_extensions
    end
  end

  class LookupContext < ActionView::LookupContext
    def initialize(app, details = {}, prefixes = [])
      view_paths = [
        app.source_dir
      ]

      super(view_paths, details, prefixes)
    end
  end

  class Template < ::ActionView::Template
  end

  # class Resolver < ::ActionView::Resolver

  class View
    include ::ActionView::Helpers, ::ERB::Util, ::ActionView::Context

    def assign(new_assigns) # :nodoc:
      @_assigns = new_assigns.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    def initialize(context = nil, assigns = {}, controller = nil, formats = nil) #:nodoc:
      @_config = ActiveSupport::InheritableOptions.new

      # if context.is_a?(ActionView::Renderer)
        @view_renderer = context
      # else
      #   lookup_context = context.is_a?(ActionView::LookupContext) ?
      #     context : ActionView::LookupContext.new(context)
      #   lookup_context.formats  = formats if formats
      #   lookup_context.prefixes = controller._prefixes if controller
      #   @view_renderer = ActionView::Renderer.new(lookup_context)
      # end

      assign(assigns)
      # assign_controller(controller)
      _prepare_context
    end
  end
end

#           # view_context_class looks for "_helpers"
#           # (@app.helper_modules || []).each do |h|
#           #   if h.is_a? Module
#           #     self.class.send(:include, h)
#           #   else
#           #     self.class.class_eval(&h)
#           #   end
#           # end

#         # def method_missing(method, *args)
#         #   if @app.config.respond_to?(method)
#         #     @app.config.send(method, *args)
#         #   elsif @app.respond_to?(method)
#         #     @app.send(method, *args)
#         #   else
#         #     super
#         #   end
#         # end

#         # def respond_to?(method, include_private = false)
#         #   super || @app.config.respond_to?(method) || @app.respond_to?(method)
#         # end
      

#     #   # Setup extension
#     #   class << self

#     #     # Once registered
#     #     def registered(app)
#     #       # # Include methods
#     #       # app.send :include, InstanceMethods
#     #       # app.helpers HelperMethods

#     #       # app.define_hook :before_render
#     #       # app.define_hook :after_render

#     #       # ::Tilt.mappings.delete('html') # WTF, Tilt?
#     #       # ::Tilt.mappings.delete('csv')

#     #       # require 'active_support/core_ext/string/output_safety'

#     #       # # Activate custom renderers
#     #       # require "middleman-core/renderers/erb"
#     #       # app.register Middleman::Renderers::ERb

#     #       # # CoffeeScript Support
#     #       # begin
#     #       #   require "middleman-core/renderers/coffee_script"
#     #       #   app.register Middleman::Renderers::CoffeeScript
#     #       # rescue LoadError
#     #       # end

#     #       # # Haml Support
#     #       # begin
#     #       #   require "middleman-core/renderers/haml"
#     #       #   app.register Middleman::Renderers::Haml
#     #       # rescue LoadError
#     #       # end

#     #       # # Sass Support
#     #       # begin
#     #       #   require "middleman-core/renderers/sass"
#     #       #   app.register Middleman::Renderers::Sass
#     #       # rescue LoadError
#     #       # end

#     #       # # Markdown Support
#     #       # require "middleman-core/renderers/markdown"
#     #       # app.register Middleman::Renderers::Markdown

#     #       # # Liquid Support
#     #       # begin
#     #       #   require "middleman-core/renderers/liquid"
#     #       #   app.register Middleman::Renderers::Liquid
#     #       # rescue LoadError
#     #       # end

#     #       # # Slim Support
#     #       # begin
#     #       #   require "middleman-core/renderers/slim"
#     #       #   app.register Middleman::Renderers::Slim
#     #       # rescue LoadError
#     #       # end

#     #       # # Less Support
#     #       # begin
#     #       #   require "middleman-core/renderers/less"
#     #       #   app.register Middleman::Renderers::Less
#     #       # rescue LoadError
#     #       # end

#     #       # # Stylus Support
#     #       # begin
#     #       #   require "middleman-core/renderers/stylus"
#     #       #   app.register Middleman::Renderers::Stylus
#     #       # rescue LoadError
#     #       # end

#     #       # # Clean up missing Tilt exts
#     #       # app.after_configuration do
#     #       #   Tilt.mappings.each do |key, klasses|
#     #       #     begin
#     #       #       Tilt[".#{key}"]
#     #       #     rescue LoadError, NameError
#     #       #       Tilt.mappings.delete(key)
#     #       #     end
#     #       #   end
#     #       # end
#     #     end

#     #     alias :included :registered
#     #   end

#     #   # module HelperMethods
#     #   #   # Allow layouts to be wrapped in the contents of other layouts
#     #   #   # @param [String, Symbol] layout_name
#     #   #   # @return [void]
#     #   #   def wrap_layout(layout_name, &block)
#     #   #     layout_path = @app.locate_layout(layout_name, current_engine)

#     #   #     extension = File.extname(layout_path)
#     #   #     engine = extension[1..-1].to_sym

#     #   #     # Store last engine for later (could be inside nested renders)
#     #   #     self.save_engine(engine)

#     #   #     begin
#     #   #       content = if block_given?
#     #   #         capture_html(&block)
#     #   #       else
#     #   #         ""
#     #   #       end
#     #   #     end
#     #   #     concat_content @app.render_individual_file(layout_path, @current_locs || {}, @current_opts || {}, self) { content }
#     #   #   ensure
#     #   #     self.restore_engine
#     #   #   end
#     #   # end


#     #   # Rendering instance methods
#     #   module InstanceMethods


#     #     def context
#     #       # Use a dup of self as a context so that instance variables set within
#     #       # the template don't persist for other templates.
#     #       @_template_context ||= Context.generate(self)
#     #     end

#     #     # Get the template data from a path
#     #     # @param [String] path
#     #     # @return [String]
#     #     def template_data_for_file(path)
#     #       File.read(File.expand_path(path, source_dir))
#     #     end

#     #     # Get a hash of configuration options for a given file extension, from
#     #     # config.rb
#     #     #
#     #     # @param [String] ext
#     #     # @return [Hash]
#     #     # def options_for_ext(ext)
#     #     #   # Read options for extension from config/Tilt or cache
#     #     #   cache.fetch(:options_for_ext, ext) do
#     #     #     options = {}

#     #     #     # Find all the engines which handle this extension in tilt. Look for
#     #     #     # config variables of that name and merge it
#     #     #     extension_class = ::Tilt[ext]
#     #     #     ::Tilt.mappings.each do |mapping_ext, engines|
#     #     #       next unless engines.include? extension_class
#     #     #       engine_options = config[mapping_ext.to_sym] || {}
#     #     #       options.merge!(engine_options)
#     #     #     end

#     #     #     options
#     #     #   end
#     #     # end
#     #   end
#     # end
#   end
# end
