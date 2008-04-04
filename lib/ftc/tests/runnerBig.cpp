/* Generated file, do not edit */

#ifndef CXXTEST_RUNNING
#define CXXTEST_RUNNING
#endif

#define _CXXTEST_HAVE_EH
#include <cxxtest/TestListener.h>
#include <cxxtest/TestTracker.h>
#include <cxxtest/TestRunner.h>
#include <cxxtest/RealDescriptions.h>
#include <cxxtest/StdioPrinter.h>

int main() {
 return CxxTest::StdioPrinter().run();
}
#include "TestLargeFileSuite.h"

static TestLargeFileSuite suite_TestLargeFileSuite;

static CxxTest::List Tests_TestLargeFileSuite = { 0, 0 };
CxxTest::StaticSuiteDescription suiteDescription_TestLargeFileSuite( "TestLargeFileSuite.h", 18, "TestLargeFileSuite", suite_TestLargeFileSuite, Tests_TestLargeFileSuite );

static class TestDescription_TestLargeFileSuite_testREAD20Gb : public CxxTest::RealTestDescription {
public:
 TestDescription_TestLargeFileSuite_testREAD20Gb() : CxxTest::RealTestDescription( Tests_TestLargeFileSuite, suiteDescription_TestLargeFileSuite, 275, "testREAD20Gb" ) {}
 void runTest() { suite_TestLargeFileSuite.testREAD20Gb(); }
} testDescription_TestLargeFileSuite_testREAD20Gb;

#include <cxxtest/Root.cpp>
