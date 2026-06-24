# Parth Patel
# N01779255
# Assigntask : H

* **Brief Problem Summary:** Breaks down why the `DueDate` constraint errors were causing issues during testing and how the system needs to safely test records with 0 lines.
* **Solution Overview:** Outlines the transaction isolation strategy (`BEGIN TRANSACTION` + `ROLLBACK TRANSACTION`) used to manipulate the state temporarily without breaking data integrity rules or leaving mock junk behind.
* **Execution Instructions:** Provides clean, runnable scripts for the 4th test case utilizing **positional execution parameters** just as requested.
* **Assumptions:** Details structural requirements regarding schemas (`AdventureWorks2022`), table keys, and procedure positional layouts.
