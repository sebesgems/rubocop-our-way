# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength

require 'rubocop'

module RuboCop
  module Cop
    module OurWay
      # Ensures controllers under the spell scope inherit from Sebes::SpellController.
      #
      # Controllers routed under `scope path: :spell` in routes.rb must inherit
      # from `Sebes::SpellController` to ensure consistent behavior.
      #
      # This cop identifies spell controllers by:
      # - File path containing '/spell/' directory (including in engines)
      # - Controller class being in a Spell module namespace (including in engines)
      #
      # @example
      #   # bad
      #   class TokensController < ApplicationController
      #   end
      #
      #   # bad
      #   module Spell
      #     class TokensController < ApplicationController
      #     end
      #   end
      #
      #   # bad - engine controller in spell namespace
      #   module Paymentfarm
      #     module Spell
      #       class PurchasesController < ApplicationController
      #       end
      #     end
      #   end
      #
      #   # good
      #   class TokensController < Sebes::SpellController
      #   end
      #
      #   # good
      #   module Spell
      #     class TokensController < Sebes::SpellController
      #     end
      #   end
      #
      #   # good - engine controller in spell namespace
      #   module Paymentfarm
      #     module Spell
      #       class PurchasesController < Sebes::SpellController
      #       end
      #     end
      #   end
      #
      class SpellControllerInheritance < ::RuboCop::Cop::Base
        MSG = 'Controllers under the spell scope must inherit from `Sebes::SpellController`, not `%<parent>s`.'

        def on_class(node)
          return unless controller_file?
          return unless spell_context?(node)
          return unless controller_class?(node)
          return if correct_parent?(node.parent_class)

          parent_name = node.parent_class.source
          add_offense(node.parent_class, message: format(MSG, parent: parent_name))
        end

        private

        def controller_file?
          processed_source.file_path.end_with?('_controller.rb')
        end

        def spell_context?(node)
          # Check file path for /spell/ directory
          file_path = processed_source.file_path
          return true if file_path.include?('/spell/')

          # Check if this specific node is inside a Spell module (anywhere in the hierarchy)
          return true if in_spell_module?(node)

          # Check if controller is routed under spell scope in routes file
          in_spell_routes?
        end

        def in_spell_module?(node)
          # Check if this node or any of its ancestors is a Spell module
          current = node
          while current
            return true if current.module_type? && current.identifier.const_name == 'Spell'

            current = current.parent
          end
          false
        end

        def controller_class?(node)
          # Check if the class name ends with 'Controller'
          class_name = node.identifier.const_name
          class_name.end_with?('Controller')
        end

        def in_spell_routes?
          return false unless routes_file_path

          @in_spell_routes ||= check_routes_for_spell_scope
        end

        def routes_file_path
          @routes_file_path ||= find_routes_file
        end

        def find_routes_file
          file_path = processed_source.file_path

          # Check if this is an engine controller
          engine_routes = find_engine_routes(file_path)
          return engine_routes if engine_routes

          # Check main app routes
          find_app_routes(file_path)
        end

        def find_engine_routes(file_path)
          return nil unless file_path.include?('/engines/')

          match = file_path.match(%r{/engines/([^/]+)/})
          return nil unless match

          engine_name = match[1]
          engine_root = file_path.split('/engines/')[0]
          routes_path = File.join(engine_root, 'engines', engine_name, 'config', 'routes.rb')
          File.exist?(routes_path) ? routes_path : nil
        end

        def find_app_routes(file_path)
          app_root = find_app_root(file_path)
          return nil unless app_root

          routes_path = File.join(app_root, 'config', 'routes.rb')
          File.exist?(routes_path) ? routes_path : nil
        end

        def find_app_root(file_path)
          parts = file_path.split('/')
          # Look for 'app' directory and get its parent
          app_index = parts.rindex('app')
          return nil unless app_index&.positive?

          parts[0..(app_index - 1)].join('/')
        end

        def check_routes_for_spell_scope
          return false unless routes_file_path

          controller_name = extract_controller_route_name
          routes_content = File.read(routes_file_path)

          # Parse the routes file to check if controller is in spell scope
          in_spell_scope?(routes_content, controller_name)
        rescue StandardError
          # If we can't read/parse routes, default to false
          false
        end

        def extract_controller_route_name
          file_path = processed_source.file_path
          # Extract controller name from file path
          # e.g., engines/blik/app/controllers/blik/purchases_controller.rb -> purchases
          # or app/controllers/users_controller.rb -> users
          File.basename(file_path, '_controller.rb')
        end

        def in_spell_scope?(routes_content, controller_name)
          # Simple heuristic: look for "scope path: :spell" followed by the controller
          # This uses regex to find spell scope blocks and check if controller is mentioned

          # Match scope blocks with :spell
          scope_pattern = /scope\s+path:\s*:spell.*?do(.*?)end/m
          routes_content.scan(scope_pattern).each do |scope_block|
            # Check if controller is referenced in this scope block
            # Look for resources, resource, get, post, etc. with the controller name
            return true if scope_block[0] =~ /resources?\s+:#{controller_name}/
            return true if scope_block[0] =~ /['"]#{controller_name}['"]/
            return true if scope_block[0] =~ /#{controller_name}#/
          end

          false
        end

        def correct_parent?(parent)
          return false unless parent

          # Accept Sebes::SpellController or any subclass of it
          parent_source = parent.source
          return true if direct_spell_controller?(parent_source)

          # Check if parent inherits from Sebes::SpellController
          inherits_from_spell_controller?(parent_source, parent)
        end

        def direct_spell_controller?(parent_source)
          valid_names = ['Sebes::SpellController', '::Sebes::SpellController', 'SpellController']
          valid_names.include?(parent_source)
        end

        def inherits_from_spell_controller?(class_name, context_node)
          # Try to find the class definition in the current file, considering namespace
          class_def = find_class_definition(class_name, context_node)
          return false unless class_def
          return false unless class_def.parent_class

          parent_source = class_def.parent_class.source
          return true if direct_spell_controller?(parent_source)

          # Recursively check the parent's parent
          inherits_from_spell_controller?(parent_source, class_def.parent_class)
        end

        def find_class_definition(class_name, context_node)
          # Try to find in current file first
          result = find_class_in_current_file(class_name, context_node)
          return result if result

          # If not found in current file, try to find in external file
          find_class_in_external_file(class_name)
        end

        def find_class_in_current_file(class_name, context_node)
          root = get_root_node(context_node)
          namespace = get_namespace_from_context(context_node)

          # Try to find with the namespace first (for relative references)
          if namespace.any?
            namespaced_name = "#{namespace.join('::')}::#{class_name}"
            result = find_class_in_node(root, namespaced_name)
            return result if result
          end

          # Try to find without namespace (absolute reference or top-level)
          find_class_in_node(root, class_name)
        end

        def get_root_node(node)
          root = node
          root = root.parent while root.parent
          root
        end

        def find_class_in_external_file(class_name)
          file_path = class_name_to_file_path(class_name)
          return nil unless file_path && File.exist?(file_path)

          begin
            source = File.read(file_path)
            ast = RuboCop::ProcessedSource.new(source, target_ruby_version).ast
            return nil unless ast

            find_class_in_node(ast, class_name)
          rescue StandardError
            nil
          end
        end

        def class_name_to_file_path(class_name)
          # Convert class name to file path: Api::SebesAbstractController -> api/sebes_abstract_controller.rb
          file_name = convert_class_name_to_path(class_name)
          search_for_class_file(file_name)
        end

        def convert_class_name_to_path(class_name)
          parts = class_name.split('::')
          parts.map { |part| underscore(part) }.join('/')
        end

        def search_for_class_file(file_name)
          current_file = processed_source.file_path

          # Try current context (engine or app)
          app_root = find_app_root(current_file)
          path = try_find_in_root(app_root, file_name) if app_root
          return path if path

          # If in an engine, also try main app root
          check_main_app_root(current_file, file_name)
        end

        def check_main_app_root(current_file, file_name)
          return nil unless current_file.include?('/engines/')

          workspace_root = find_workspace_root(current_file)
          workspace_root ? try_find_in_root(workspace_root, file_name) : nil
        end

        def try_find_in_root(root, file_name)
          # Try app/controllers first
          controller_path = File.join(root, 'app', 'controllers', "#{file_name}.rb")
          return controller_path if File.exist?(controller_path)

          # Try lib directory
          lib_path = File.join(root, 'lib', "#{file_name}.rb")
          return lib_path if File.exist?(lib_path)

          nil
        end

        def find_workspace_root(file_path)
          # For engine files: engines/blik/app/... -> get the root before engines/
          return nil unless file_path.include?('/engines/')

          parts = file_path.split('/engines/')
          root = parts[0]
          # Handle relative paths where the root might be empty
          root.empty? ? '.' : root
        end

        def underscore(word)
          word.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
              .gsub(/([a-z\d])([A-Z])/, '\1_\2')
              .downcase
        end

        def target_ruby_version
          @target_ruby_version ||= config.target_ruby_version
        end

        def get_namespace_from_context(node)
          modules = []
          current = node.parent
          while current
            modules.unshift(current.identifier.const_name) if add_to_namespace?(current, node)
            current = current.parent
          end
          modules
        end

        def add_to_namespace?(current, node)
          return true if current.module_type?
          return false unless current.class_type?

          current != node
        end

        def find_class_in_node(node, class_name)
          return nil unless node
          return node if matching_class?(node, class_name)

          search_children_for_class(node, class_name)
        end

        def matching_class?(node, class_name)
          return false unless node.class_type?

          found_class_name = extract_class_name(node)
          found_class_name == class_name || node.identifier.const_name == class_name
        end

        def search_children_for_class(node, class_name)
          node.children.each do |child|
            next unless child.is_a?(RuboCop::AST::Node)

            result = find_class_in_node(child, class_name)
            return result if result
          end
          nil
        end

        def extract_class_name(class_node)
          simple_name = class_node.identifier.const_name
          modules = extract_module_names(class_node)

          modules.any? ? "#{modules.join('::')}::#{simple_name}" : simple_name
        end

        def extract_module_names(class_node)
          modules = []
          current = class_node.parent
          while current
            modules.unshift(current.identifier.const_name) if current.module_type?
            current = current.parent
          end
          modules
        end
      end
    end
  end
end

# rubocop:enable Metrics/ClassLength
