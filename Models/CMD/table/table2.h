// v50207, by Ray Sells, DESE Research, Inc.
#ifndef TABLE2_H
#define TABLE2_H

#include "strtok.h"
#include "table.h"

namespace tframes {

class Table2 : public Table {
  public:
    Table2( const char *fname);
    void read( char *tabname, bool echo);
    double interp( double xi1, double xi2);
    int test( int n);
    double operator()( double x, double y) { return interp( x, y);};
  private:
    string x1name, x2name, yname;
    double *y;
    int nx1, nx2;
    double *x1, *x2;
    friend ostream &operator<<( ostream &stream, Table2);
};

ostream &operator<<( ostream &stream, Table2);

}
#endif
