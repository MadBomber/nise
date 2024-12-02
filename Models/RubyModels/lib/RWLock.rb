
class RWLock
      class Counter
        def initialize(ts, rw_name, name)
          @ts, @rw_name, @name = ts, rw_name, name
        end

        def init(n = 0)
          update(n)
        end

        def modify
          t = @ts.take [@rw_name, @name, nil]
          result = yield t
          @ts.write t
          result
        end
        private :modify

        def inc
          modify{|t| t[2] += 1}
        end

        def dec
          modify{|t| t[2] -= 1}
        end

        def wait(n, oper = :take)
          @ts.send oper, [@rw_name, @name, n]
        end

        def update(n)
          @ts.write [@rw_name, @name, n]
        end
      end

      def initialize(ts, name)
        @ts, @name = ts, name
        @dispenser = Counter.new(@ts, @name, 'dispenser')
        @reader = Counter.new(@ts, @name, 'reader')
        @turn = Counter.new(@ts, @name, 'turn')
      end

      def init
        @dispenser.init(-1)
        @reader.init
        @turn.init
      end

      class << self
        def create(*args)
          result = new(*args)
          result.init
          result
        end

        alias_method :find, :new

        def exists?(ts, name)
          not ts.read_all([name, 'dispenser', nil]).empty?
        end
      end

      def read_lock
        ticket = @dispenser.inc
        @turn.wait(ticket)
        @reader.inc
        @turn.update(ticket + 1)
      end

      def read_unlock
        @reader.dec
      end

      def write_lock
        @ticket = @dispenser.inc
        @turn.wait(@ticket)
        @reader.wait(0, :read)
      end

      def write_unlock
        @turn.update(@ticket + 1)
      end
    end


