
module DeliverySugar
  class Exceptions
    # Raise when a cookbook said to be a cookbook is not a valid cookbook
    class NotACookbook < RuntimeError
      def initialize(path)
        @path = path
      end

      def to_s
        <<-EOM
  The directory below is not a valid cookbook:
  #{@path}
        EOM
      end
    end
  end
end
