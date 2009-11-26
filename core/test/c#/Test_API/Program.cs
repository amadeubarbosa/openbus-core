using System;
using System.Reflection;


namespace Test_API
{
  static class Program
  {
    ///
    /// The main entry point for the application.
    ///
    [STAThread]
    static void Main(string[] args) {
      String[] arguments = new String[]{
        Assembly.GetExecutingAssembly().Location,
        "/domain=none"
      };
      
      NUnit.ConsoleRunner.Runner.Main(arguments);
      Console.WriteLine("\nDone.");
      Console.ReadLine();
    }
  }
}


