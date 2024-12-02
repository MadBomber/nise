
class BoundedQueue
      def initialize(ts, name)
        @ts, @name = ts, name
      end

      SIZE, LENGTH, FULL, EMPTY = (2..5).to_a

      def init(size)
        @ts.write [:bqueue, :tail, @name, 0]
        @ts.write [:bqueue, :head, @name, 1]
        length = 0
        full = false
        empty = true
        @ts.write [:bqueue, :status, size, length, full, empty]
      end

      class << self
        def create(ts, name, size)
          result = new(ts, name)
          result.init(size)
          result
        end

        alias_method :find, :new
      end

      def send(data)
        # read unless queue is full
        status = @ts.take [:bqueue, :status, nil, nil, false, nil]

        # update status
        status[LENGTH] += 1
        status[FULL] = status[SIZE] == status[LENGTH]
        status[EMPTY] = status[LENGTH] == 0

        tail = @ts.take [:bqueue, :tail, @name, nil]
        tail[3] += 1

        @ts.write status
        @ts.write [:bqueue, @name, tail[3], data]
        @ts.write tail
      end

      def read
        # read unless queue is empty
        status = @ts.take [:bqueue, :status, nil, nil, nil, false]

        # update status
        status[LENGTH] -= 1
        status[FULL] = status[SIZE] == status[LENGTH]
        status[EMPTY] = status[LENGTH] == 0

        head = @ts.take [:bqueue, :head, @name, nil]
        t = @ts.take [:bqueue, @name, head[3], nil]
        head[3] += 1

        @ts.write status
        @ts.write head

        t[3]
      end

      def each
        loop do
          yield read
        end
      end
    end


