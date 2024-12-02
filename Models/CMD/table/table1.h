// v50207, by Ray Sells, DESE Research, Inc.
#ifndef TABLE1_H
#define TABLE1_H

#include "strtok.h"
#include "table.h"

namespace tframes {

class Table1 : public Table {
  public:
    Table1( const char *fname);
    void read( char *tabname, bool echo);
    void readCSF_thrust( bool echo);
    double interp( double xi);
    int test( int n);
    double operator()( double x) { return interp( x);};
  private:
    string x1name, yname;
    double *y;
    int nx1;
    double *x1;

    friend ostream &operator<<( ostream &stream, Table1);
};

ostream &operator<<( ostream &stream, Table1);

}
#endif
