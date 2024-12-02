
class Queue
      def initialize(ts, name)
        @ts, @name = ts, name
      end

      def init
        @ts.write [:queue, :tail, @name, 0]
        @ts.write [:queue, :head, @name, 1]
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
        tail = @ts.take [:queue, :tail, @name, nil]
        tail[3] += 1
        @ts.write [:queue, @name, tail[3], data]
        @ts.write tail
      end

      def read
        head = @ts.take [:queue, :head, @name, nil]
        t = @ts.take [:queue, @name, head[3], nil]
        head[3] += 1
        @ts.write head
        t[3]
      end

      def each
        loop do
          yield read
        end
      end
    end


