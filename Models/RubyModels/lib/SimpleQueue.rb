
class SimpleQueue
      def initialize(ts, name)
        @ts, @name = ts, name
      end

      def init
        @ts.write [:squeue, :tail, @name, 0]
      end

      class << self
        def create(*args)
          result = new(*args)
          result.init
          result
        end

        alias_method :find, :new
      end

      def send(data)
        tail = @ts.take [:squeue, :tail, @name, nil]
        tail[3] += 1
        @ts.write [:squeue, @name, tail[3], data]
        @ts.write tail
      end

      def each
        pos = 1
        loop do
          t = @ts.read [:squeue, @name, pos, nil]
          yield t[3]
          pos += 1
        end
      end
    end

# Example Usage:
# Producer:

    loop do
      msg = create_message()
      squeue.send msg
    end

# Consumer:

    def process(a_message)
      puts a_message
    end

    squeue.each do |msg|
      process(msg)
    end



