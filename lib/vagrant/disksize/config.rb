module Vagrant
  module Disksize
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :size

      SIZE_REGEX = /^(?<number>[0-9]+)\s?(?<scale>KB|MB|GB|TB)?$/

      def initialize
        @size = UNSET_VALUE
      end

      def finalize!
        return if @size == UNSET_VALUE
        # Convert from human to machine readable
        size_str = @size.to_s.strip
        matches = SIZE_REGEX.match(size_str)
        if matches
          number = matches[:number]
          scale = matches[:scale]
          @size = number.to_i
          if scale
            pos = %w(KB MB GB TB).index(scale)
            mult = 1 << 10*(pos+1)
            @size *= mult
          end
        end
        # Convert size from bytes to MB
        size_in_mb = (@size.to_i + (1<<20)-1) / (1<<20)
        @size = size_in_mb
      end

      def validate(machine)
        errors = []

        unless @size.to_s =~ SIZE_REGEX
          errors << "'#{@size}' is not a valid specification of disk size"
        end

        return { 'Disksize configuration' => errors }
      end

    end
  end
end

