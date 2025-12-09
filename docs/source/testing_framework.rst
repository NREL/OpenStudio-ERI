Testing Framework
=================

A large number of tests are automatically run for every code change in the GitHub repository.

The current set of tests include:

- Successful ERI calculations for all sample files
- RESNET® HERS® tests (ASHRAE 140, HVAC tests, etc.)
- EPA ENERGY STAR tests

HERS Accreditation
------------------

If you are seeking to develop RESNET Accredited Rating Software, you will need to submit your final software product to `RESNET for accreditation <https://www.resnet.us/providers/accredited-providers/hers-software-tools/>`_.

.. note::

  There are some additional things the software will need to do (e.g., generate RESNET National Building Registry XML) according to `RESNET Publication 002 - Procedures for Verification of RESNET Accredited HERS Software Tools <https://www.resnet.us/providers/accredited-providers/hers-software-tools/>`_.

Running Tests Locally
---------------------

All RESNET HERS tests can be run using:

| ``openstudio resnet_hers_test.rb``

All EPA ENERGY STAR & DOE Efficient New Homes (formerly Zero Energy Ready Homes) tests can be run using:

| ``openstudio es_denh_test.rb``

Or individual tests can be run by specifying the name of the test. A couple examples:

| ``openstudio resnet_hers_test.rb --name=test_resnet_ashrae_140``
| ``openstudio es_denh_test.rb --name=test_epa``

Test results in CSV format are created at ``workflow/tests/test_results`` and can be used to populate RESNET Excel spreadsheet forms.
RESNET acceptance criteria are also implemented as part of the tests to check for test failures.

At the completion of the test, there will be output that denotes the number of failures/errors like so:

| ``Finished in 36.067116s, 0.0277 runs/s, 0.9704 assertions/s. 1 runs, 35 assertions, 0 failures, 0 errors, 0 skips``

.. note::

  Software developers may find it convenient to export HPXML files with the same name as the test files included in the repository.
  This allows issuing the commands above to generate test results.

Official Test Results
---------------------

The official OpenStudio-ERI test results can be found in any release or any checkout of the code at ``workflow/tests/base_results``.
The results are based on using the HPXML files found under ``workflow/tests``.
