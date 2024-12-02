// HelloWorld.java

import java.util.*;

public class HelloWorld
{

  // method main(): ALWAYS the APPLICATION entry point
  public static void main (String[] args)
  {
    
    System.out.println("\n");
    System.out.println("   Hello World       J");
    System.out.println("  Hello   World      A");
    System.out.println(" Hello     World     V R");
    System.out.println("Hello       World    A U");
    System.out.println(" Hello     World       L");
    System.out.println("  Hello   World        E");
    System.out.println("   Hello World         S");
    System.out.println("\nThe local time coordinate is:");
  	System.out.println(new Date());
  	
    int size = args.length;
    
    if(size > 0)
    {

      System.out.println ("\nThe command line parameters are:");
      for (int i=0; i<size; i++)
      {
        System.out.println(args[i]);
      }
    
    }
    else
    {
    
      System.out.println ("\n\nThere no command line parameters");
      
    } // end of if(size > 0)

    System.out.println();
    
  } // end of public static void main (String[] args
    
} // end of public class HelloWorld


