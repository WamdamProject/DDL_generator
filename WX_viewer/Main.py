# -*- coding: utf-8 -*- 

###########################################################################
## Python code generated with wxFormBuilder (version Jun 17 2015)
## http://www.wxformbuilder.org/
##
## PLEASE DO "NOT" EDIT THIS FILE!
###########################################################################

import wx
import wx.xrc

###########################################################################
## Class frm_home
###########################################################################

class frm_home ( wx.Frame ):
	
	def __init__( self, parent ):
		wx.Frame.__init__ ( self, parent, id = wx.ID_ANY, title = u"DDL Creator Wizard", pos = wx.DefaultPosition, size = wx.Size( 822,989 ), style = wx.DEFAULT_FRAME_STYLE|wx.TAB_TRAVERSAL )

		self.SetSizeHintsSz( wx.DefaultSize, wx.DefaultSize )

		bSizer1 = wx.BoxSizer( wx.VERTICAL )

		self.m_staticText3 = wx.StaticText( self, wx.ID_ANY, u"Welcome to the Data Definition Language (DDL) creator 1.0", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText3.Wrap( -1 )
		self.m_staticText3.SetFont( wx.Font( 15, 70, 90, 92, False, wx.EmptyString ) )

		bSizer1.Add( self.m_staticText3, 0, wx.ALL|wx.ALIGN_CENTER_HORIZONTAL, 5 )

		gSizer5 = wx.GridSizer( 3, 2, 0, 0 )

		self.m_staticText21 = wx.StaticText( self, wx.ID_ANY, u"Select the XML Database Schema ", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText21.Wrap( -1 )
		self.m_staticText21.SetFont( wx.Font( wx.NORMAL_FONT.GetPointSize(), 70, 90, 92, False, wx.EmptyString ) )

		gSizer5.Add( self.m_staticText21, 0, wx.ALL, 5 )

		self.filePicker_xmlfile = wx.FilePickerCtrl( self, wx.ID_ANY, wx.EmptyString, u"Select a file", u"XML files (*.xml ,*.XML)|*.xml;*.XML", wx.DefaultPosition, wx.DefaultSize, wx.FLP_DEFAULT_STYLE )
		gSizer5.Add( self.filePicker_xmlfile, 0, wx.ALL, 5 )

		self.checkBox_sequentialKeys = wx.CheckBox( self, wx.ID_ANY, u"Create sequential primary keys ?", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer5.Add( self.checkBox_sequentialKeys, 0, wx.ALL, 5 )

		self.checkBox_CaseSensitivity = wx.CheckBox( self, wx.ID_ANY, u"Maintain case sensitivity", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.checkBox_CaseSensitivity.SetValue(True)
		gSizer5.Add( self.checkBox_CaseSensitivity, 0, wx.ALL, 5 )

		self.m_staticText16 = wx.StaticText( self, wx.ID_ANY, u"Global Schema name", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText16.Wrap( -1 )
		gSizer5.Add( self.m_staticText16, 0, wx.ALL, 5 )

		self.textCtrl_GlobalSchema = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer5.Add( self.textCtrl_GlobalSchema, 0, wx.ALL, 5 )

		self.checkBox_CreateDDLs = wx.CheckBox( self, wx.ID_ANY, u"Create DDL for all Dbs", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.checkBox_CreateDDLs.SetValue(True)
		gSizer5.Add( self.checkBox_CreateDDLs, 0, wx.ALL, 5 )


		bSizer1.Add( gSizer5, 0, 0, 5 )

		self.m_staticText5 = wx.StaticText( self, wx.ID_ANY, u"Select whic RDBS you want to build the schema for\nEdit a descriptive test to be added on top of the DDL text file to describe your schema", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText5.Wrap( -1 )
		bSizer1.Add( self.m_staticText5, 0, wx.ALL, 5 )

		gSizer7 = wx.GridSizer( 0, 2, 0, 0 )

		self.m_staticText10 = wx.StaticText( self, wx.ID_ANY, u"Add your name and possition to print it to the DDL file", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText10.Wrap( -1 )
		gSizer7.Add( self.m_staticText10, 0, wx.ALL, 5 )

		self.textCtrl_UserName = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer7.Add( self.textCtrl_UserName, 1, wx.ALL, 5 )

		self.m_staticText13 = wx.StaticText( self, wx.ID_ANY, u"Date of generating the file", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText13.Wrap( -1 )
		gSizer7.Add( self.m_staticText13, 0, wx.ALL, 5 )

		self.textCtrl_Date = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer7.Add( self.textCtrl_Date, 0, wx.ALL, 5 )


		bSizer1.Add( gSizer7, 1, wx.EXPAND, 5 )

		self.m_staticline6 = wx.StaticLine( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LI_HORIZONTAL )
		bSizer1.Add( self.m_staticline6, 0, wx.EXPAND |wx.ALL, 5 )

		gSizer3 = wx.GridSizer( 2, 2, 0, 0 )

		self.checkBox_Sqlite = wx.CheckBox( self, wx.ID_ANY, u"SQLite. Output DDL file name:", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.checkBox_Sqlite.SetValue(True)
		gSizer3.Add( self.checkBox_Sqlite, 0, wx.ALL, 5 )

		self.textCtrl_SqliteFileName = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer3.Add( self.textCtrl_SqliteFileName, 1, wx.ALL, 5 )

		self.m_staticText6 = wx.StaticText( self, wx.ID_ANY, u"Description comment inside the DDL file", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText6.Wrap( -1 )
		gSizer3.Add( self.m_staticText6, 0, wx.ALL, 5 )

		self.textCtrl_SQLiteFileDesc = wx.TextCtrl( self, wx.ID_ANY, u"-- This is a Data Definition Language (DDL) script that\n-- generates a blank schema of the Water Management Data Model (WaM-DaM)\n-- for SQLite database\n\n-- Generated\n-- Adel Abdallah \n--May 1, 2017\n-- based on WaM-DaM XML design named --WaMDaMMay1_2017.xml \n--generated by DbWrench V4.03 @ http://www.dbwrench.com\n-- WaMDaM All rights reserved. See Licence @ wamdam.org \n\n--Use the SQLite Manager Add-on to Mozilla Firefox\n--Create a new empty database. Click on the Execute SQL button and delete the text \"SELECT * FROM tablename\"\n--Simply copy all this script and paste into this Execute SQL window\n--Then click Run SQL. The script should run successfully and create the 41 empty tables of WaM-DaM", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer3.Add( self.textCtrl_SQLiteFileDesc, 0, wx.ALL|wx.EXPAND, 5 )


		bSizer1.Add( gSizer3, 1, wx.EXPAND, 5 )

		self.m_staticline4 = wx.StaticLine( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LI_HORIZONTAL )
		bSizer1.Add( self.m_staticline4, 0, wx.EXPAND |wx.ALL, 5 )

		gSizer41 = wx.GridSizer( 0, 2, 0, 0 )

		self.m_checkBox3 = wx.CheckBox( self, wx.ID_ANY, u"Postgres. Output DDL file name:", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_checkBox3.SetValue(True)
		gSizer41.Add( self.m_checkBox3, 0, wx.ALL, 5 )

		self.textCtrl_PostgresFileName = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer41.Add( self.textCtrl_PostgresFileName, 0, wx.ALL, 5 )

		self.m_staticText61 = wx.StaticText( self, wx.ID_ANY, u"Description comment inside the DDL file", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText61.Wrap( -1 )
		gSizer41.Add( self.m_staticText61, 0, wx.ALL, 5 )

		self.textCtrl_PostgresFileDesc = wx.TextCtrl( self, wx.ID_ANY, u"--This is a Data Definition Language (DDL) script that\n--generates a blank schema of the Water Management Data Model (WaMDaM)\n--for PostgreSQL database\n\n-- Generated by \n--Adel Abdallah \n--May1, 2017\n-- based on WaMDaM XML design named --WaMDaMMay1_2017.xml \n--DbWrench V4.0 @ http://www.dbwrench.com\n-- WaMDaM All rights reserved. See Licence @ wamdam.org \n\n--Open PostgreSQL, click on Databases>> Postgers>>   at the left Object Browser panel\n--Simply copy all this script and paste into the new window of \"SQL query\"\n--Then click execute. The script should run successfully and create the 41 empty tables of WaM-DaM\"", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer41.Add( self.textCtrl_PostgresFileDesc, 0, wx.ALL|wx.EXPAND, 5 )


		bSizer1.Add( gSizer41, 1, wx.EXPAND, 5 )

		self.m_staticline61 = wx.StaticLine( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LI_HORIZONTAL )
		bSizer1.Add( self.m_staticline61, 0, wx.EXPAND |wx.ALL, 5 )

		gSizer51 = wx.GridSizer( 0, 2, 0, 0 )

		self.m_checkBox4 = wx.CheckBox( self, wx.ID_ANY, u"SQL Server. Output DDL file name:", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_checkBox4.SetValue(True)
		gSizer51.Add( self.m_checkBox4, 0, wx.ALL, 5 )

		self.textCtrl_MSSQLFileName = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer51.Add( self.textCtrl_MSSQLFileName, 0, wx.ALL, 5 )

		self.m_staticText611 = wx.StaticText( self, wx.ID_ANY, u"Description comment inside the DDL file", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText611.Wrap( -1 )
		gSizer51.Add( self.m_staticText611, 0, wx.ALL, 5 )

		self.textCtrl_MSSQLFileDesc = wx.TextCtrl( self, wx.ID_ANY, u"--This is a Data Definition Language (DDL) script that\n--generates a blank schema of the Water Management Data Model (WaMDaM)\n-- for Microsoft SQL Server database.\n\n-- Generated by \n--Adel Abdallah\n--May 1, 2017\n--based on WaMDaM XML design named --WaMDaMMay1_2017.xml\n--generated by DbWrench V4.03 @ http://www.dbwrench.com/\n-- WaMDaM All rights reserved. See Licence @ wamdam.org \n\n-- To create a blank WaM-DaM database in SQL Server,\n-- Open SQL Server, Click File >> New >> Query with Current Condition\n-- Simply copy all this script and paste into the new window of \"create query\"\n-- Then click \"execute\". The script should run successfully and create the 41 empty tables of WaM-DaM", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer51.Add( self.textCtrl_MSSQLFileDesc, 0, wx.ALL|wx.EXPAND, 5 )


		bSizer1.Add( gSizer51, 1, wx.EXPAND, 5 )

		self.m_staticline71 = wx.StaticLine( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LI_HORIZONTAL )
		bSizer1.Add( self.m_staticline71, 0, wx.EXPAND |wx.ALL, 5 )

		gSizer6 = wx.GridSizer( 0, 2, 0, 0 )

		self.m_checkBox5 = wx.CheckBox( self, wx.ID_ANY, u"MySQL. Output DDL file name:", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_checkBox5.SetValue(True)
		gSizer6.Add( self.m_checkBox5, 0, wx.ALL, 5 )

		self.textCtrl_MySQLFileName = wx.TextCtrl( self, wx.ID_ANY, wx.EmptyString, wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer6.Add( self.textCtrl_MySQLFileName, 0, wx.ALL, 5 )

		self.m_staticText6111 = wx.StaticText( self, wx.ID_ANY, u"Description comment inside the DDL file", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText6111.Wrap( -1 )
		gSizer6.Add( self.m_staticText6111, 0, wx.ALL, 5 )

		self.textCtrl_MySQLFileDesc = wx.TextCtrl( self, wx.ID_ANY, u"-- This is a Data Definition Language (DDL) script that\n-- generates a blank schema of the Water Management Data Model (WaM-DaM)\n-- for MySQL database\n\n-- Generated by \n--Adel Abdallah \n--May 1, 2017\n--based on WaMDaM XML design named --WaMDaMMay1_2017.xml \n--generated by DbWrench V4.03 @ http://www.dbwrench.com\n-- WaMDaM All rights reserved. See Licence @ wamdam.org \n\n--Open MySQL Workbench, Create a New SQL Tab for Executing queries\n--Simply copy all this script and paste into the new window of \"create query\"\n--Then click execute. The script should run successfully and create the 41 empty tables of WaM-DaM", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer6.Add( self.textCtrl_MySQLFileDesc, 0, wx.ALL|wx.EXPAND, 5 )


		bSizer1.Add( gSizer6, 1, wx.EXPAND, 5 )

		self.m_staticline8 = wx.StaticLine( self, wx.ID_ANY, wx.DefaultPosition, wx.DefaultSize, wx.LI_HORIZONTAL )
		bSizer1.Add( self.m_staticline8, 0, wx.EXPAND |wx.ALL, 5 )

		self.m_staticText2 = wx.StaticText( self, wx.ID_ANY, u"Select where you want your database files to be created to", wx.DefaultPosition, wx.DefaultSize, 0 )
		self.m_staticText2.Wrap( -1 )
		bSizer1.Add( self.m_staticText2, 0, wx.ALL, 5 )

		self.dirPicker_DDLfiles = wx.DirPickerCtrl( self, wx.ID_ANY, wx.EmptyString, u"Select a folder", wx.DefaultPosition, wx.DefaultSize, wx.DIRP_DEFAULT_STYLE )
		bSizer1.Add( self.dirPicker_DDLfiles, 0, wx.ALL|wx.EXPAND, 5 )

		gSizer4 = wx.GridSizer( 1, 2, 0, 0 )

		self.button_generate = wx.Button( self, wx.ID_ANY, u"Generate", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer4.Add( self.button_generate, 0, wx.ALL|wx.ALIGN_BOTTOM|wx.ALIGN_RIGHT, 5 )

		self.button_cancel = wx.Button( self, wx.ID_ANY, u"Cancel", wx.DefaultPosition, wx.DefaultSize, 0 )
		gSizer4.Add( self.button_cancel, 0, wx.ALL|wx.ALIGN_BOTTOM, 5 )


		bSizer1.Add( gSizer4, 1, wx.EXPAND, 5 )


		self.SetSizer( bSizer1 )
		self.Layout()
		self.m_statusBar4 = self.CreateStatusBar( 1, wx.ST_SIZEGRIP, wx.ID_ANY )
		self.m_menubar3 = wx.MenuBar( 0 )
		self.m_menu3 = wx.Menu()
		self.m_menuItem1 = wx.MenuItem( self.m_menu3, wx.ID_ANY, u"MyMenuItem", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu3.AppendItem( self.m_menuItem1 )

		self.m_menuItem2 = wx.MenuItem( self.m_menu3, wx.ID_ANY, u"MyMenuItem", wx.EmptyString, wx.ITEM_NORMAL )
		self.m_menu3.AppendItem( self.m_menuItem2 )

		self.m_menubar3.Append( self.m_menu3, u"About" )

		self.SetMenuBar( self.m_menubar3 )


		self.Centre( wx.BOTH )

		# Connect Events
		self.filePicker_xmlfile.Bind( wx.EVT_FILEPICKER_CHANGED, self.filePicker_xmlfileOnFileChanged )
		self.dirPicker_DDLfiles.Bind( wx.EVT_DIRPICKER_CHANGED, self.dirPicker_DDLfilesOnDirChanged )
		self.button_generate.Bind( wx.EVT_BUTTON, self.button_generateOnButtonClick )
		self.button_cancel.Bind( wx.EVT_BUTTON, self.button_cancelOnButtonClick )

	def __del__( self ):
		pass


	# Virtual event handlers, overide them in your derived class
	def filePicker_xmlfileOnFileChanged( self, event ):
		event.Skip()

	def dirPicker_DDLfilesOnDirChanged( self, event ):
		event.Skip()

	def button_generateOnButtonClick( self, event ):
		event.Skip()

	def button_cancelOnButtonClick( self, event ):
		event.Skip()
	

