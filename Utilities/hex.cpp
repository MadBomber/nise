#include <iomanip>
#include <iostream>
#include <sstream>

using namespace std;

main(int argc,char **argv)
{
  int k;
  cout<<"    oct          dec        hex"<<endl;
  for(int i=1; i<argc; i++){
    istringstream in(argv[i]);
    in>>setbase(0)>>k;
    cout<<setw(11)<<oct<<k<<setw(12)<<dec<<k<<setw(10)<<hex<<k<<endl;
  }
}
