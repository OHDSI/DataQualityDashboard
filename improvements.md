Improve parallel scanning:
- Configure aborting by User for parallel scanning

Improve abort checking:
    
- Do call abort checking frequently
- In java catch block fetch scan status from db and compare it with ABORT status

Remove writing error reports to the files - transfer to database

Add user ability to set types of Data Quality Checks

Docker R container - set env on run stage