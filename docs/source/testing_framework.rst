Testing Framework
=================

A large number of tests are automatically run for every code change in the GitHub repository.

Types of Tests
--------------

The current set of tests include:

- Successful ERI calculations for all sample files
- RESNET® ANSI/ASHRAE Standard 140-2011, Class II, Tier 1 Tests
- RESNET HERS® Reference Home auto-generation tests
- RESNET HERS Index Adjustment Design auto-generation tests
- RESNET HERS method tests
- RESNET HVAC tests
- RESNET Duct distribution system efficiency tests
- RESNET Hot water system performance tests

Test Results
------------

Test results in CSV format can be found on the `CI machine <https://circleci.com/gh/NREL/OpenStudio-ERI>`_ for any build under the "Artifacts" tab.

If you are seeking to develop RESNET Accredited Rating Software, you will need to submit your final software product to RESNET for accreditation.
Note that EnergyPlus cannot currently pass the ANSI/ASHRAE Standard 140-2011 tests, for which test criteria were set by decades old simulation engines.
There have been discussions about updating the test criteria using EnergyPlus and other modern simulation engines, but nothing has been done to date.
In order to apply for RESNET accreditation, software developers will need to use the "Process for Exceptions and Appeals" in the Procedures for Verification of RESNET Accredited HERS Software Tools document.

Running Tests Locally
---------------------

Tests can also be run locally, as shown below. Individual tests (any method in workflow/tests/energy_rating_index_test.rb that begins with "test\_") can also be run. For example:  

- All tests: ``openstudio energy_rating_index_test.rb``
- Method tests only: ``openstudio energy_rating_index_test.rb --name=test_resnet_hers_method``

Test results in CSV format are created at workflow/tests/test_results. 
For many RESNET tests, the Excel spreadsheet test criteria are also implemented in code to automate the process of checking for test failures.

At the completion of the test, there will also be output that denotes the number of failures/errors like so:

``Finished in 36.067116s, 0.0277 runs/s, 0.9704 assertions/s.``
``1 runs, 35 assertions, 0 failures, 0 errors, 0 skips``

Software developers may find it convenient to export HPXML files with the same name as the test files included in the repository.
This allows issuing the same commands above to generate test results.
