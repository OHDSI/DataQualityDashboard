DQD Developers README
====================

Dev Setup 
====================
1. R setup: https://ohdsi.github.io/Hades/rSetup.html  
2. Local OMOP CDM setup 

   If you already have a CDM available for development work/testing, you may skip this step 
   
   a. Install Postgres and create a localhost server 
   
   b. Create a new database in localhost for your test CDM, and create a schema in that database for the CDM tables 
   
   c.Using the CDMConnector package:

       i.  Download a sample OMOP CDM into a DuckDB database, as documented here 
       ii. Copy the CDM into your local Postgres database, as documented here 
 3.Fork the DataQualityDashboard repo 

 4.Clone your fork to your computer 
 
PR Process 
====================

Be sure you're aware of our Pull Request guidelines before diving into development work: https://github.com/OHDSI/DataQualityDashboard/blob/main/.github/pull_request_template.md  
1.  Sync your fork's develop branch with the upstream repo 
2. Check out and pull the develop branch of your fork  
3. Create a new branch named (briefly) according to the issue being fixed / feature being added 

    a.  If possible, limit the changes made on each branch to those needed for a single GitHub issue 
    
    b.  If an issue or new feature requires extensive changes, split your work across multiple sub-branches off of your feature branch, or across multiple feature branches 
4. Make your changes 

    a. If you are adding new functionality, you must add unit tests to cover the new function(s)/code 
    
    b. If you are fixing a bug, you must add a unit test for the regression 
5. Run R CMD Check and resolve all errors, warnings, and notes 
  
   a. At the time of writing, the NOTE regarding the size of the package is expected and does not need to be resolved 
6. Run `test_file(path = "tests/testthat/test-executeDqChecks.R")` and resolve all test failures 
   
   a. This file contains tests using testthat's snapshot feature, which do not work when tests are run via R CMD Check 

   b. See testthat docs to learn more about snapshots and how to resolve snapshot test failures: https://testthat.r-lib.org/articles/snapshotting.html  
7. Build & install the package locally, then run DQD against your local Postgres database and view the results. Resolve any errors that arise 
8. Commit your changes and push them to GitHub 
9. Back on GitHub, open up a PR for your changes, making sure to set the target branch to the `develop` branch of the parent OHDSI/DataQualityDashboard repo 
10. Wait for the automated checks to complete 

    a. If they all succeed, your PR is ready for review! 

    b. If any checks fail, check the logs and address errors in your code by repeating steps 4-7 above 
11. Once your PR is approved by a maintainer, you may merge it into the `develop` branch 
 
General Guidance 
====================
HADES Developer Guidelines: https://ohdsi.github.io/Hades/developerGuidelines.html  
HADES Code Style Requirements: https://ohdsi.github.io/Hades/codeStyle.html  
HADES Release Process: https://ohdsi.github.io/Hades/releaseProcess.html 
 