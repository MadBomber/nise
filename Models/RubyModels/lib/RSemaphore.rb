
=begin
the case of the failing client. What about the best strategy to handle a
failing client that has taken a resource off the ts.

There are at least two approaches:

1) To leave the resource in the ts during the update/work but mark
it as read-only via a secondary tuple itself with an expiration value.

If the consumer carries out its processing on/of the resource and relinquishes it properly, all is fine.

If the consumer crashes while it has de facto ownership of the
resource, the secondary tuple will eventually expire hence releasing
the resource for another consumer to 'take'.

2) To have producers monitor the lifecycle of the resources thay put
in the ts and reincarnate them, should a consumer blow up or take the
tuple too long.

preference for the first approach 

=end


class RSemaphore
      def initialize(ts, name)
        @ts, @name = ts, name
      end

      class << self
        def create(ts, name, num)
          result = new(ts, name)
          result.init(num)
          result
        end

        alias_method :find, :new

        def exists?(ts, name)
          not ts.read_all([:rsemaphore, name]).empty?
        end
      end

      def init(num)
        num.times do
          @ts.write [:rsemaphore, @name]
        end
      end

      def down
        @ts.take [:rsemaphore, @name]
      end

      def up
        @ts.write [:rsemaphore, @name]
      end
    end

# Example Usage
#    require "RSemaphore"
    name = 'printer'

    sem = RSemaphore.exists?(ts, name) ? 
            RSemaphore.find(ts, name) : 
            RSemaphore.create(ts, name, 3)

    puts "#{$$}: requests resource"
    sem.down
    puts "#{$$}: resource taken"
    sleep rand(5)
    sem.up
    puts "#{$$}: resource released"





