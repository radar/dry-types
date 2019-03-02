module Dry
  module Types
    class Compiler
      attr_reader :registry

      def initialize(registry)
        @registry = registry
      end

      def call(ast)
        visit(ast)
      end

      def visit(node)
        type, body = node
        send(:"visit_#{ type }", body)
      end

      def visit_constrained(node)
        definition, rule, meta = node
        Types::Constrained.new(visit(definition), rule: visit_rule(rule)).meta(meta)
      end

      def visit_constructor(node)
        definition, fn_register_name, meta = node
        fn = Dry::Types::FnContainer[fn_register_name]
        primitive = visit(definition)
        Types::Constructor.new(primitive, meta: meta, fn: fn)
      end

      def visit_safe(node)
        ast, meta = node
        Types::Safe.new(visit(ast), meta: meta)
      end

      def visit_definition(node)
        type, meta = node

        if registry.registered?(type)
          registry[type].meta(meta)
        else
          Definition.new(type, meta: meta)
        end
      end

      def visit_rule(node)
        Dry::Types.rule_compiler.([node])[0]
      end

      def visit_sum(node)
        *types, meta = node
        types.map { |type| visit(type) }.reduce(:|).meta(meta)
      end

      def visit_array(node)
        member, meta = node
        member = member.is_a?(Class) ? member : visit(member)
        registry['array'].of(member).meta(meta)
      end

      def visit_hash(node)
        keys, meta = node
        registry['hash'].schema(keys.map { |key| visit(key) }, meta)
      end

      def visit_json_hash(node)
        keys, meta = node
        registry['json.hash'].schema(keys.map { |key| visit(key) }, meta)
      end

      def visit_json_array(node)
        member, meta = node
        registry['json.array'].of(visit(member)).meta(meta)
      end

      def visit_params_hash(node)
        keys, meta = node
        registry['params.hash'].schema(keys.map { |key| visit(key) }, meta)
      end

      def visit_params_array(node)
        member, meta = node
        registry['params.array'].of(visit(member)).meta(meta)
      end

      def visit_key(node)
        name, required, type = node
        Hash::Key.new(visit(type), name, required: required)
      end

      def visit_enum(node)
        type, mapping, meta = node
        Enum.new(visit(type), mapping: mapping, meta: meta)
      end

      def visit_map(node)
        key_type, value_type, meta = node
        registry['hash'].map(visit(key_type), visit(value_type)).meta(meta)
      end
    end
  end
end
