Testing Framework
=================

A large number of tests are automatically run for every code change in the GitHub repository.

The current set of tests include:

- Successful ERI calculations for all sample files
- RESNET® ANSI/ASHRAE Standard 140-2011, Class II, Tier 1 Tests
- RESNET HERS® Reference Home auto-generation tests
- RESNET HERS Index Adjustment Design auto-generation tests
- RESNET HERS method tests
- RESNET HVAC tests
- RESNET Duct distribution system efficiency tests
- RESNET Hot water system performance tests

If you are seeking to develop RESNET Accredited Rating Software, you will need to submit your final software product to RESNET for accreditation.

Running Tests Locally
---------------------

All tests can be run locally using:
``openstudio energy_rating_index_test.rb``

Individual tests (any method in workflow/tests/energy_rating_index_test.rb that begins with "test\_") can also be run.
For example:  
``openstudio energy_rating_index_test.rb --name=test_resnet_hers_method``

All current HERS tests can be run using as follows:
``openstudio energy_rating_index_test.rb --name=test_resnet_ashrae_140``
``openstudio energy_rating_index_test.rb --name=test_resnet_hers_reference_home_auto_generation``
``openstudio energy_rating_index_test.rb --name=test_resnet_hers_method``
``openstudio energy_rating_index_test.rb --name=test_resnet_hvac``
``openstudio energy_rating_index_test.rb --name=test_resnet_dse``
``openstudio energy_rating_index_test.rb --name=test_resnet_hot_water``

Test results in CSV format are created at workflow/tests/test_results. 
For many RESNET tests, the Excel spreadsheet test criteria are also implemented in code to automate the process of checking for test failures.
All simulation/HPXML/etc. files generated from running the tests can be found inside the workflow/tests/test_files directory.

At the completion of the test, there will also be output that denotes the number of failures/errors like so:

``Finished in 36.067116s, 0.0277 runs/s, 0.9704 assertions/s.``
``1 runs, 35 assertions, 0 failures, 0 errors, 0 skips``

Software developers may find it convenient to export HPXML files with the same name as the test files included in the repository.
This allows issuing the same commands above to generate test results.
