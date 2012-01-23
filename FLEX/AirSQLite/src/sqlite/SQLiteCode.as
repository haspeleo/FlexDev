
//http://www.flex-blog.com/adobe-air-sqlite-example/
// ActionScript file

import flash.data.SQLStatement;
import flash.errors.SQLError;
import flash.events.Event;
import flash.events.SQLErrorEvent;
import flash.events.SQLEvent;
import flash.events.TimerEvent;
import flash.filesystem.File;
import flash.utils.Timer;

import mx.collections.ArrayCollection;
import mx.controls.Alert;
import mx.utils.ObjectUtil;

import org.osmf.events.TimeEvent;

// sqlc is a variable we need to define the connection to our database
private var sqlc:SQLConnection = new SQLConnection();
// sqlc is an SQLStatment which we need to execute our sql commands
private var sqls:SQLStatement = new SQLStatement();
// ArrayCollection used as a data provider for the datagrid. It has to be bindable so that data in datagrid changes automatically when we change the ArrayCollection
[Bindable]
private var dp:ArrayCollection = new ArrayCollection();

// function we call at the begining when application has finished loading and bulding itself
private function start():void
{
	// first we need to set the file class for our database (in this example test.db). If the Database doesn't exists it will be created when we open it.
	var db:File = File.applicationStorageDirectory.resolvePath("test.db");
	// after we set the file for our database we need to open it with our SQLConnection.
	sqlc.openAsync(db);
	// we need to set some event listeners so we know if we get an sql error, when the database is fully opened and to know when we recive a resault from an sql statment. The last one is uset to read data out of database.
	sqlc.addEventListener(SQLEvent.OPEN, db_opened);
	sqlc.addEventListener(SQLErrorEvent.ERROR, error);
	sqls.addEventListener(SQLErrorEvent.ERROR, error);
	sqls.addEventListener(SQLEvent.RESULT, resault);
	
}

private function db_opened(e:SQLEvent):void
{
	// when the database is opened we need to link the SQLStatment to our SQLConnection, so that sql statments for the right database.
	// if you don't set this connection you will get an error when you execute sql statment.
	sqls.sqlConnection = sqlc;
	// in property text of our SQLStatment we write our sql command. We can also combine sql statments in our text property so that more than one statment can be executed at a time.
	// in this sql statment we create table in our database with name "test_table" with three columns (id, first_name and last_name). Id is an integer that is auto incremented when each item is added. First_name and last_name are columns in which we can store text
	// If you want to know more about sql statments search the web.
	sqls.text = "CREATE TABLE IF NOT EXISTS test_table ( id INTEGER PRIMARY KEY AUTOINCREMENT, first_name TEXT, last_name TEXT);";
	// after we have connected sql statment to our sql connection and writen our sql commands we also need to execute our sql statment.
	// nothing will change in database until we execute sql statment.
	sqls.execute();
	// after we load the database and create the table if it doesn't already exists, we call refresh method which i have created to populate our datagrid
	refresh();
}
// function to add item to our database
private function addItem():void
{
	// in this sql statment we add item at the end of our table with values first_name.text in column first_name and last_name.text for column last_name
	sqls.text = "INSERT INTO test_table (first_name, last_name) VALUES('"+first_name.text+"','"+last_name.text+"');";
	sqls.execute();
	
	refresh();
}

// function to call when we want to refresh the data in datagrid
private function refresh(e:TimerEvent = null):void {
	
	// timer object which we need if sql statment is still executing so that we can try again after 10 milliseconds.
	var timer:Timer = new Timer(10,1);
	timer.addEventListener(TimerEvent.TIMER, refresh);
	
	if ( !sqls.executing )// we need to check if our sql statment is still executing our last sql command. If so we use Timer to try again in 10 milliseconds. If we wouldn't check we could get an error because SQLStatment can't execute two statments at the same time.
	{
		// sql statment which returns all the data from our "test_table". To retrive only data from first_name and last_name columns we would use "SELECT first_name,last_name FROM test_table"
		sqls.text = "SELECT * FROM test_table"
		sqls.execute();
	}
	else {
		timer.start();
	}
}

// method that gets called if we recive some resaults from our sql commands.
//this method would also get called for sql statments to insert item and to create table but in this case sqls.getResault().data would be null
private function resault(e:SQLEvent):void
{
	// with sqls.getResault().data we get the array of objects for each row out of our database
	var data:Array = sqls.getResult().data;
	// we pass the array of objects to our data provider to fill the datagrid
	dp = new ArrayCollection(data);
}

// method to remove row from database.
private function remove():void
{
	// sql statment to delete from our test_table the row that has the same number in number column as our selected row from datagrid
	sqls.text = "DELETE FROM test_table WHERE id="+dp[dg.selectedIndex].id;
	sqls.execute();
	refresh();
}
// method which gets called when we recive an error  from sql connection or sql statment and displays the error in the alert
private function error(e:SQLErrorEvent):void
{
	Alert.show(e.toString());
}