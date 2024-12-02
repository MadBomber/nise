// v50207, by Ray Sells, DESE Research, Inc.
#ifndef TABLE3_H
#define TABLE3_H

#include "strtok.h"
#include "table.h"

namespace tframes {

class Table3 : public Table {
  public:
    Table3( const char *fname);
    void read( char *tabname, bool echo);
    double interp( double xi1, double xi2, double xi3);
    int test( int n);
    double operator()( double x, double y, double z)
      { return interp( x, y, z);};
  private:
    string x1name, x2name, x3name, yname;
    double *y;
    int nx1, nx2, nx3;
    double *x1, *x2, *x3;
    friend ostream &operator<<( ostream &stream, Table3);
};

ostream &operator<<( ostream &stream, Table3);

}
#endif
