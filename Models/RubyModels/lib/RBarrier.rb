
class RBarrier
      def initialize(ts, name)
        @ts, @name = ts, name
      end

      class << self
        def create(ts, name, num)
          result = new(ts, name)
          result.init(num)
          result
        end

        def exists?(ts, name)
          not ts.read_all([:rbarrier, name, nil, nil]).empty?
        end

        alias_method :find, :new
      end

      def init(num)
        @ts.write [:rbarrier, @name, num, 0]
      end

      def wait
        t = @ts.take [:rbarrier, @name, nil, nil]
        t[3] += 1
        @ts.write t
        @ts.read [:rbarrier, @name, t[2], t[2]]
      end
    end



# Example usage:
#    require "rbarrier"
    name = 'barrier'

    barrier = RBarrier.exists?(ts, name) ?
                RBarrier.find(ts, name) :
                RBarrier.create(ts, name, 3)

    puts "#{$$}: waiting..."
    barrier.wait
    puts "#{$$}: done."



