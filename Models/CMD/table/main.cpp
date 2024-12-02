// v50207, by Ray Sells, DESE Research, Inc.
#include <iostream>
#include "strtok.h"
#include "table1.h"
#include "table2.h"
#include "table3.h"
using namespace std;

int main() {
  char *fname = "table.dat";

  // Strtok example
  tframes::StrTok *f = new tframes::StrTok( fname, " =");
  vector<string> vlines = f->readlines();
  for( int i = 0; i < ( int)vlines.size(); i++) {
    vector<string> vs;
    if( vlines[i].find( "thrust_mag") != string::npos) {
      vs = f->str_split( vlines[i]);
      double thrust = atof( vs[1].c_str());
      cout << vs[0] << " = " << thrust << endl;
      break;
    }
  }

  // Table1 example
  tframes::Table1 *tab1 = new tframes::Table1( fname);
  tab1->read( "thrust_profile", true);
  if( tab1->test( 1000)) {
    cout << tab1->interp( 1.412) << endl;
    cout << (*tab1)( 1.302) << endl; // another way to interp
    tframes::Table1 t1( fname);
    t1.read( "thrust_profile", true);
    cout << t1( 1.304) << endl; // another way to interp
  }

  // Table2 example
  tframes::Table2 *tab2 = new tframes::Table2( fname);
  tab2->read( "cd_table", true);
  if( tab2->test( 1000)) {
    cout << tab2->interp( 2.0, 11.0) << endl;
    cout << (*tab2)( 3.0, 11.0) << endl; // another way to interp
    tframes::Table2 &t2 = *tab2;
    cout << t2( 4.0, 11.0) << endl; // another way to interp
  }

  // Table3 example
  tframes::Table3 *tab3 = new tframes::Table3( fname);
  tab3->read( "cd_table_thrust", true);
  if( tab3->test( 1000)) {
    cout << tab3->interp( 1.5, 8, 5) << endl;
    tframes::Table3 &t3 = *tab3;
    cout << t3( 1.6, 8, 5) << endl; // another way to interp
  }
  exit( 1);

  // inserter overloaded for easy output
  cout << "\n";
  cout << *tab1 << endl;
  cout << *tab2 << endl;
  cout << *tab3 << endl;
  return 0;
}
