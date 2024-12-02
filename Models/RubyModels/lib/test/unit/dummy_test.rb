# This is because rcov chokes, when there are no test cases found.

require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__

class DummyTest < Test::Unit::TestCase
  def test_truth
    assert true
  end
end


