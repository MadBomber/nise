/**
 * \file ExponentialProb.hpp
 * \brief Header for ExponentialProb
 *
 * Return true with probabililty exp(-\e p).
 *
 * Written by <a href="http://charles.karney.info/">Charles Karney</a>
 * <charles@karney.com> and licensed under the LGPL.  For more
 * information, see http://charles.karney.info/random/
 **********************************************************************/

#if !defined(EXPONENTIALPROB_H)
#define EXPONENTIALPROB_H

#define RCSID_EXPONENTIALPROB_H "$Id: ExponentialProb.hpp 6410 2007-11-09 21:55:50Z ckarney $"

#include <vector>
#include <limits>

#if !defined(STATIC_ASSERT)
/**
 * A simple compile-time assert.
 **********************************************************************/
#define STATIC_ASSERT(cond) { enum{ STATIC_ASSERT_ENUM = 1/int(cond) }; }
#endif

namespace RandomLib {
  /**
   * \brief The exponential probability.
   *
   * Return true with probability exp(-\e p).  Basic method taken from:\n
   * J. von Neumann,\n Various Techniques used in Connection with Random
   * Digits,\n J. Res. Nat. Bur. Stand., Appl. Math. Ser. 12, 36-38 (1951),\n
   * reprinted in Collected Works, Vol. 5, 768-770 (Pergammon, 1963).\n See
   * also the references given for the ExactExponential class.
   *
   * Here the method is extended to be exact by generating sufficient bits in
   * the random numbers in the algorithm to allow the unambiguous comparisons
   * to be made.
   *
   * Here's one way of sampling from a normal distribution with zero mean and
   * unit variance in the interval [-1,1] with reasonable accuracy:
   * \code
   * #include "RandomLib/Random.hpp"
   * #include "RandomLib/ExponentialProb.hpp"
   *
   * double Normal(RandomLib::Random& r) {
   *   double x;
   *   RandomLib::ExponentialProb e;
   *   do
   *      x = r.FloatW();
   *   while ( !e(r, - 0.5 * x * x) );
   *   return x;
   * }
   * \endcode
   **********************************************************************/
  class ExponentialProb {
  private:
    typedef unsigned word;
  public:

    ExponentialProb() : _v(std::vector<word>(alloc_incr)) {}
    /**
     * Return true with probability exp(-\e p).  Returns false if \e p <= 0.
     * For in \e p (0,1], it requires about exp(\e p) random deviates.  For \e
     * p large, it requires about exp(1)/(1 - exp(-1)) random deviates.
     **********************************************************************/
    template<typename RealType, class Random>
    bool operator()(Random& r, RealType p) const throw(std::bad_alloc);

  private:
    /**
     * Return true with probability exp(-\e p) for \e p in [0,1].
     **********************************************************************/
    template<typename RealType, class Random>
    bool ExpFraction(Random& r, RealType p) const throw(std::bad_alloc);
    /**
     * Holds as much of intermediate uniform deviates as needed.
     **********************************************************************/
    mutable std::vector<word> _v;
    /**
     * Increment on size of _v.
     **********************************************************************/
    static const unsigned alloc_incr = 16;
  };

  template<typename RealType, class Random>
  inline bool ExponentialProb::operator()(Random& r, RealType p) const
    throw(std::bad_alloc) {
    return p <= 0 ||		// True if p <=0
      // Ensure p - 1 < p.  Also deal with IsNaN(p)
      p < RealType(1)/std::numeric_limits<RealType>::epsilon() &&
      // exp(a+b) = exp(a) * exp(b)
      ExpFraction(r, p < RealType(1) ? p : RealType(1)) &&
      ( p <= RealType(1) || operator()(r, p - RealType(1)) );
  }

  template<typename RealType, class Random>
  inline bool ExponentialProb::ExpFraction(Random& r, RealType p) const
    throw(std::bad_alloc) {
    // Base of _v is 2^c.  Adjust so that word(p) doesn't lose precision.
    const int c =
      std::numeric_limits<word>::digits <
      std::numeric_limits<RealType>::digits ?
      std::numeric_limits<word>::digits :
      std::numeric_limits<RealType>::digits;
    // m gives number of valid words in _v
    unsigned m = 0, l = _v.size();
    if (p < RealType(1))
      while (true) {
	if (p <= RealType(0))
	  return true;
	// p in (0, 1)
	if (l == m)
	  _v.resize(l += alloc_incr);
	_v[m++] = r.template Integer<word, c>();
	p *= pow(RealType(2), c); // p in (0, 2^c)
	word w = word(p);	// w in [0, 2^c)
	if (_v[m - 1] > w)
	  return true;
	else if (_v[m - 1] < w)
	  break;
	else			// _v[m - 1] == w
	  p -= RealType(w);	// p in [0, 1)
      }
    // Here _v < p.  Now loop finding decreasing V.  Exit when first increasing
    // one is found.
    for (unsigned s = 0; ; s ^= 1) { // Parity of loop count
      for (size_t j = 0; ; ++j) {
	if (j == m) {
	  // Need more bits in the old V
	  if (l == m)
	    _v.resize(l += alloc_incr);
	  _v[m++] = r.template Integer<word, c>();
	}
	word w = r.template Integer<word, c>();
	if (w > _v[j])
	  return s;		// New V is bigger, so exit
	else if (w < _v[j]) {
	  _v[j] = w;		// New V is smaller, update _v
	  m = j + 1;		// adjusting its size
	  break;		// and generate the next V
	}
	// Else w == _v[j] and we need to check the next c bits
      }
    }
  }
} // namespace RandomLib
#endif	// EXPONENTIALPROB_H
