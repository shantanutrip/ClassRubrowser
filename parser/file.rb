require 'parser/current'
require_relative 'definition/class'
require_relative 'definition/module'
require_relative 'definition/methodbase'
require_relative 'definition/varbase'
require_relative 'relation/base'
require_relative 'file/builder'

module Classrubrowser
  module Parser
    class File
      FILE_SIZE_LIMIT = 2 * 1024 * 1024

      attr_reader :file, :definitions, :relations, :ast


      def initialize(file)
        @file = ::File.absolute_path(file)
        @definitions = []
        @relations = []
        @ast = nil
        @hash = {}
      end

      def parse
        return unless valid_file?(file)
        #puts "Hi"
        contents = ::File.read(file)

        buffer = ::Parser::Source::Buffer.new(file, 1)
        buffer.source = contents.force_encoding(Encoding::UTF_8)

        parser = ::Parser::CurrentRuby.new(Builder.new)
        parser.diagnostics.ignore_warnings = true
        parser.diagnostics.all_errors_are_fatal = false

        @ast = parser.parse(buffer)
        constants = parse_block(ast)
        #puts constants

        @definitions = constants[:definitions]
        @relations = constants[:relations]
      rescue ::Parser::SyntaxError
        warn "SyntaxError in #{file}"
      end

      def valid_file?(file)
        !::File.symlink?(file) &&
            ::File.file?(file) &&
            ::File.size(file) <= FILE_SIZE_LIMIT
      end

      private

      def parse_block(node, parents = [])
        return empty_result unless valid_node?(node)
        #puts node.type
        case node.type
          when :module then parse_module(node, parents)
          when :class then parse_class(node, parents)
          when :const then parse_const(node, parents)
          when :def,:define_method then parse_method(node, parents)
          when :lvasgn then parse_var(node, parents)
          else parse_array(node.children, parents)
        end
      end

      def parse_var(node, parents = [])
        namespace = ast_consts_to_array(node.children.first, parents)
        definition = Definition::Varbase.new(
            namespace,
            file: file,
            line: node.loc.line,
            lines: node.loc.last_line - node.loc.line + 1,
            cols: node.loc.column,
            lastCols: node.loc.last_column
        )
        constants = { definitions: [definition] }
        children_constants = parse_array(node.children[1..-1], namespace)

        merge_constants(children_constants, constants)

        #puts "parse_var"
        #puts node.loc.line
        #key = node.children[0]
        #val = ast_consts_to_array((node.children[1]).children[0])
        #puts key
        #puts val

      end

      def parse_module(node, parents = [])
        namespace = ast_consts_to_array(node.children.first, parents)
        definition = Definition::Module.new(
            namespace,
            file: file,
            line: node.loc.line,
            lines: node.loc.last_line - node.loc.line + 1,
            cols: node.loc.column,
            lastCols: node.loc.last_column
        )
        constants = { definitions: [definition] }
        children_constants = parse_array(node.children[1..-1], namespace)

        merge_constants(children_constants, constants)
      end

      def parse_method(node, parents = [])
        namespace = parents + [node.children.first]
        definition = Definition::Methodbase.new(
            namespace,
            file: file,
            line: node.loc.line,
            lines: node.loc.last_line - node.loc.line + 1,
            cols: node.loc.column,
            lastCols: node.loc.last_column
        )
        constants = { definitions: [definition] }
        children_constants = parse_array(node.children[1..-1], namespace)

        merge_constants(children_constants, constants)
      end

      def parse_class(node, parents = [])
        namespace = ast_consts_to_array(node.children.first, parents)
        definition = Definition::Class.new(
            namespace,
            file: file,
            line: node.loc.line,
            lines: node.loc.last_line - node.loc.line + 1,
            cols: node.loc.column,
            lastCols: node.loc.last_column
        )
        constants = { definitions: [definition] }
        children_constants = parse_array(node.children[1..-1], namespace)

        merge_constants(children_constants, constants)
      end

      def parse_const(node, parents = [])
        #puts "p"
        #puts node
        #puts parents
        constant = ast_consts_to_array(node)
        definition = Relation::Base.new(
            constant,
            parents,
            file: file,
            line: node.loc.line,
            cols: node.loc.column,
            lastCols: node.loc.last_column
        )
        { relations: [definition] }
      end

      def parse_array(arr, parents = [])
        arr.map { |n| parse_block(n, parents) }
            .reduce { |a, e| merge_constants(a, e) }
      end

      def merge_constants(c1, c2)
        c1 ||= {}
        c2 ||= {}
        {
            definitions: c1[:definitions].to_a + c2[:definitions].to_a,
            relations: c1[:relations].to_a + c2[:relations].to_a
        }
      end

      def ast_consts_to_array(node, parents = [])
        #why will we ever get an invalid node - incase of null
        #if any is false, then parent returned
        #parent is returned if and only if the node is invalid or
        #of not type cnst or cbase
        return parents unless valid_node?(node) &&
            [:const, :cbase].include?(node.type)
=begin
        p "s.trip.s"
        p node
        p node.children
        p node.children.first
        p node.children.last
        p "s.trip.e"
=end
        #If of type const or cbase
        ast_consts_to_array(node.children.first, parents) + [node.children.last]
      end

      def empty_result
        {}
      end

      def valid_node?(node)
        node.is_a?(::Parser::AST::Node)
      end
    end
  end
end
