This ReadMe text helps you create blank database schemas for MySQL, MS SQL Server, SQLite, and PostgreSQL, at once. You only provide the XML Schema from DBWrench to the script.

Adel M. Abdallah
June 15, 2016

Last updated: April 2, 2018 
------------------ 

Open the CMD Terminal 
Windows>Start>Accessories>CMD

First navigate to the folder where all the Python script resides 
stay the same directory of 
C:\Users\AdelMabdallah\Desktop
cd Desktop
cd DDL

Edit the name of XML Schema in the build_ddl.py python file and the default schema name 
For example:
input_file = WaMDaM_DBWrench_Schema_1.01
default_schema = WaMDaM_DBWrench_Schema_1.01

Change the text in "Translater.py" that will print out the name of the schema and metadata in each DDL file 

% Execute this command line at the CMD terminal while still at the directory above
% copy and past this line after you change the WaMDaM.xml name below 




build_ddl.py -d all -x WaMDaM_DBWrench_Schema_1.01.xml -o wamdam_ddl





the Pythos script should build four DDL schemas.......done 


