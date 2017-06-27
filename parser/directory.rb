require_relative 'file'
require_relative 'relation/base'
module Classrubrowser
  module Parser
    class Directory
      attr_reader :directory
      attr_reader :parsers

      def initialize(directory)
        @directory = directory
        files = Dir.glob(::File.join(directory, '**', '*.rb'))
        @parsers = files.map { |f| File.new(f) }
      end

      def parse
        parsers.each(&:parse)
      end

      def definitions
        parsers.map(&:definitions).map(&:to_a).reduce([], :+)
      end

      def relations
        parsers.map(&:relations).map(&:to_a).reduce([], :+)
      end



    end
  end
end