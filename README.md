# Create Django app for a working python script to convert XML to four DDL RDBS schemas: MSSQ, MySQL, SQLite, and PostGreSQL

*The app is not ready, its in progress. You still can use the scripts_original using the Command prompt

![image](https://github.com/amabdallah/DDL_generator/blob/master/DDL_Generator.jpg)

I will deploy the app later on Amazon Web Service  
Helpful guide 
http://drksephy.github.io/2015/07/16/django/

Here is the front end of how the App should roughly look like. I built it in WxFormBuilder Version 3.5.1-RC1 but we it needs to be re-built in an html editor for a Django online app. See the wx files here
https://github.com/amabdallah/DDL_generator/tree/master/WX_viewer


![image](https://cloud.githubusercontent.com/assets/3268971/25775886/0a59f992-326d-11e7-8123-71682f0fce09.png)


**Before you start, run the app on your local machine and verify that it works as described**


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
input_file = WaMDaMMay2_2017
default_schema = WaMDaMMay2_2017

Change the text in "Translater.py" that will print out the name of the schema and metadata in each DDL file 

% Execute this command line at the CMD terminal while still at the directory above
% copy and past this line after you change thee WaM-DAM.xml name below 




*build_ddl.py -d all -x WaMDaMMay2_2017.xml -o wamdam_ddl*



the Pythos script should build four DDL schemas.......done 

![image](https://github.com/amabdallah/DDL_generator/blob/master/SnapshotOfResult_DDL_cmd.JPG)





A GUI and executable to support creating a Data Definition Language (DDL) or Structured Query Language (SQL) “create statements” to create blank databases for MySQL, MS SQL Server, SQLite, and PostgreSQL
Adel Abdallah, March 14, 2017

*Input:*
eXtensible Markup Language  (XML) file of the database schema 

translator.py
data_mapping.py
build_ddl.py
base.py
Actions:
A call function ddl_generator.py
It calls build_ddl.py and it passes the xml schema through a browser to it with an option to create the output for one of all four database systems
build_ddl.py -d all -x WaMDaMAugust19_2015.xml -o wamdam_ddl   
Add the option to the GUI to allow creating sequential primary keys or not 
Add the option to choose the name of the output files (show default, allow editing)
Given the option to edit a default commented text in each output file
other options?

**Validation checks** 
1.	Check if the provided file is an xml schema
2.	Return any error message provided by the DDL in a window  
3.	Give a message of successful creation of the database schemas 
