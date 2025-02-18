/**
 * \file RandomSelect.hpp
 * \brief Header for RandomSelect.
 *
 * An implementation of the Walker algorithm for selecting from a finite set.
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more information, see
 * http://charles.karney.info/random/
 **********************************************************************/

#if !defined(RANDOMSELECT_H)
#define RANDOMSELECT_H

#define RCSID_RANDOMSELECT_H "$Id: RandomSelect.hpp 6402 2007-05-18 12:18:46Z ckarney $"

#include <vector>
#include <limits>
#include <stdexcept>

#if !defined(STATIC_ASSERT)
/**
 * A simple compile-time assert.
 **********************************************************************/
#define STATIC_ASSERT(cond) { enum{ STATIC_ASSERT_ENUM = 1/int(cond) }; }
#endif

namespace RandomLib {
  /**
   * \brief Random selection from a discrete set.
   *
   * An implementation of Walker algorithm for selecting from a finite set
   * (following Knuth, TAOCP, Vol 2, Sec 3.4.1.A).  This provides a rapid way
   * of selecting one of several choices depending on a discrete set weights.
   * Original citation is\n A. J. Walker,\n An Efficient Method for Generating
   * Discrete Random Variables and General Distributions,\n ACM TOMS 3, 253-256
   * (1977).
   *
   * There are two changes here in the setup algorithm as given by Knuth:
   *
   * - The probabilities aren't sorted at the beginning of the setup; nor are
   * they maintained in a sorted order.  Instead they are just partitioned on
   * the mean.  This improves the setup time from O(\e k<sup>2</sup>) to O(\e
   * k).
   *
   * - The internal calculations are carried out with type \a NumericType.  If
   * the input weights are of integer type, then choosing an integer type for
   * \a NumericType yields an exact solution for the returned distribution
   * (assuming that the underlying random generator is exact.)
   *
   * Example:
   * \code
   *   #include "RandomLib/RandomSelect.hpp"
   *
   *   // Weights for throwing a pair of dice
   *   unsigned w[] = { 0, 0, 1, 2, 3, 4, 5, 6, 5, 4, 3, 2, 1 };
   *
   *   // Initialize selection
   *   RandomLib::RandomSelect<unsigned> sel(w, w + 13);
   *
   *   RandomLib::Random r;   // Initialize random numbers
   *   std::cout << "Seed set to " << r.SeedString() << std::endl;
   *
   *   std::cout << "Throw a pair of dice 100 times:";
   *   for (unsigned i = 0; i < 100; ++i)
   *       std::cout << " " << sel(r);
   *   std::cout << std::endl;
   * \endcode
   **********************************************************************/
  template<typename NumericType = double> class RandomSelect {
  public:
    /**
     * Initialize in a cleared state (equivalent to having a single
     * choice).
     **********************************************************************/
    RandomSelect() throw(std::bad_alloc) : _k(0), _wsum(0), _wmax(0) {};

    /**
     * Initialize with a weight vector \a w of elements of type \a WeightType.
     * Internal calculations are carried out with type \a NumericType.  \a
     * NumericType needs to allow Choices() * MaxWeight() to be represented.
     * Sensible combinations are:
     * - \a WeightType integer, \a NumericType integer with digits(\a
     *   NumericType) >= digits(\a WeightType)
     * - \a WeightType integer, \a NumericType real
     * - \a WeightType real, \a NumericType real with digits(\a NumericType) >=
     *   digits(\a WeightType)
     **********************************************************************/
    template<typename WeightType>
    RandomSelect(const std::vector<WeightType>& w)
      throw(std::out_of_range, std::bad_alloc) { Init(w.begin(), w.end()); }

    /**
     * Initialize with a weight given by a pair of iterators [\a a, \a b).
     **********************************************************************/
    template<typename InputIterator>
    RandomSelect(InputIterator a, InputIterator b)
      throw(std::out_of_range, std::bad_alloc);


    /**
     * Clear the state (equivalent to having a single choice).
     **********************************************************************/
    void Init() throw()
    { _k = 0; _wsum = 0; _wmax = 0; _Q.clear(); _Y.clear(); }

    /**
     * Re-initialize with a weight vector \a w.  Leave state unaltered in the
     * case of an error.
     **********************************************************************/
    template<typename WeightType>
    void Init(const std::vector<WeightType>& w)
      throw(std::out_of_range, std::bad_alloc) { Init(w.begin(), w.end()); }

    /**
     * Re-initialize with a weight given as a pair of iterators [\a a, \a b).
     * Leave state unaltered in the case of an error.
     **********************************************************************/
    template<typename InputIterator>
    void Init(InputIterator a, InputIterator b)
      throw(std::out_of_range, std::bad_alloc) {
      RandomSelect<NumericType> t(a, b);
      _Q.reserve(t._k);
      _Y.reserve(t._k);
      *this = t;
    }

    /**
     * Return an index into the weight vector with probability proportional to
     * the weight.
     **********************************************************************/
    template<class Random>
    unsigned operator()(Random& r) const throw() {
      if (_k <= 1)
	return 0;		// Special cases
      const unsigned K = r.template Integer<unsigned>(_k);
      // redundant casts to type NumericType to prevent warning from MS
      // Project
      return (std::numeric_limits<NumericType>::is_integer ?
	      r.template Prob<NumericType>(NumericType(_Q[K]),
					   NumericType(_wsum)) :
	      r.template Prob<NumericType>(NumericType(_Q[K]))) ?
	K : _Y[K];
    }

    /**
     * Return the sum of the weights.
     **********************************************************************/
    NumericType TotalWeight() const throw() { return _wsum; }

    /**
     * Return the maximum weight.
     **********************************************************************/
    NumericType MaxWeight() const throw() { return _wmax; }

    /**
     * Return the weight for sample \a i.  Weight(i) / TotalWeight() gives the
     * probability of sample \a i.
     **********************************************************************/
    NumericType Weight(unsigned i) const throw() {
      if (i >= _k)
	return NumericType(0);
      else if (_k == 1)
	return _wsum;
      const NumericType n = std::numeric_limits<NumericType>::is_integer ?
	_wsum : NumericType(1);
      NumericType p = _Q[i];
      for (unsigned j = _k; j;)
	if (_Y[--j] == i)
	  p += n - _Q[j];
      // If NumericType is integral, then p % _k == 0.
      // assert(!std::numeric_limits<NumericType>::is_integer || p % _k == 0);
      return (p / NumericType(_k)) * (_wsum / n);
    }

    /**
     * Return the number of choices, i.e., the length of the weight vector.
     **********************************************************************/
    unsigned Choices() const throw() { return _k; }

  private:

    /**
     * Size of weight vector
     **********************************************************************/
    unsigned _k;
    /**
     * Vector of cutoffs
     **********************************************************************/
    std::vector<NumericType> _Q;
    /**
     * Vector of aliases
     **********************************************************************/
    std::vector<unsigned> _Y;
    /**
     * The sum of the weights
     **********************************************************************/
    NumericType _wsum;
    /**
     * The maximum weight
     **********************************************************************/
    NumericType _wmax;

  };

  template<typename NumericType> template<typename InputIterator>
  RandomSelect<NumericType>::RandomSelect(InputIterator a, InputIterator b)
    throw(std::out_of_range, std::bad_alloc) {

    typedef typename std::iterator_traits<InputIterator>::value_type
      WeightType;
    // Disallow WeightType = real, NumericType = integer
    STATIC_ASSERT(std::numeric_limits<WeightType>::is_integer ||
		  !std::numeric_limits<NumericType>::is_integer);

    // If WeightType and NumericType are the same type, NumericType as precise
    // as WeightType
    STATIC_ASSERT(std::numeric_limits<WeightType>::is_integer !=
		  std::numeric_limits<NumericType>::is_integer ||
		  std::numeric_limits<NumericType>::digits >=
		  std::numeric_limits<WeightType>::digits);

    _wsum = 0;
    _wmax = 0;
    std::vector<NumericType> p;

    for (InputIterator wptr = a; wptr != b; ++wptr) {
      // Test *wptr < 0 without triggering compiler warning when *wptr =
      // unsigned
      if (!(*wptr > 0 || *wptr == 0))
	// This also catches NaNs
	throw std::out_of_range("RandomSelect: Illegal weight");
      NumericType w = static_cast<NumericType>(*wptr);
      if (w > (std::numeric_limits<NumericType>::max)() - _wsum)
	throw std::out_of_range("RandomSelect: Overflow");
      _wsum += w;
      _wmax = w > _wmax ? w : _wmax;
      p.push_back(w);
    }

    _k = p.size();
    if (_wsum <= 0)
      throw std::out_of_range("RandomSelect: Zero total weight");

    if (_k <= 1) {
      // We treak k <= 1 as a special case in operator()
      _Q.clear();
      _Y.clear();
      return;
    }

    if ((std::numeric_limits<NumericType>::max)()/NumericType(_k) <
	NumericType(_wmax))
      throw std::out_of_range("RandomSelect: Overflow");

    std::vector<unsigned> j(_k);
    _Q.resize(_k);
    _Y.resize(_k);

    // Pointers to the next empty low and high slots
    unsigned u = 0;
    unsigned v = _k - 1;

    // Scale input and store in p and setup index array j.  Note _wsum =
    // mean(p).  We could scale out _wsum here, but the following is exact when
    // w[i] are low integers.
    for (unsigned i = 0; i < _k; ++i) {
      p[i] *= NumericType(_k);
      j[p[i] > _wsum ? v-- : u++] = i;
    }

    // Pointers to the next low and high slots to use.  Work towards the
    // middle.  This simplifies the loop exit test to u == v.
    u = 0;
    v = _k - 1;

    // For integer NumericType, store the unnormalized probability in _Q and
    // select using the exact Prob(_Q[k], _wsum).  For real NumericType, store
    // the normalized probability and select using Prob(_Q[k]).  There will be
    // a round off error in performing the division; but there is also the
    // potential for round off errors in performing the arithmetic on p.  There
    // is therefore no point in simulating the division exactly using the
    // slower Prob(real, real).
    const NumericType n = std::numeric_limits<NumericType>::is_integer ?
      NumericType(1) : _wsum;

    while (true) {
      // A loop invariant here is mean(p[j[u..v]]) == _wsum
      _Q[j[u]] = p[j[u]] / n;

      // If all arithmetic were exact this assignment could be:
      //   if (p[j[u]] < _wsum) _Y[j[u]] = j[v];
      // But the following is safer:
      _Y[j[u]] = j[p[j[u]] < _wsum ? v : u];

      if (u == v) {
	// The following assertion may fail because of roundoff errors
	// assert( p[j[u]] == _wsum );
	break;
      }

      // Update p, u, and v maintaining the loop invariant
      p[j[v]] = p[j[v]] - (_wsum - p[j[u]]);
      if (p[j[v]] > _wsum)
	++u;
      else
	j[u] = j[v--];
    }
    return;
  }
} // namespace RandomLib
#endif // RANDOMSELECT_H
