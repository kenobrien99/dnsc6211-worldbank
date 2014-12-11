# -*- coding: utf-8 -*-
"""
Created on Sat Oct 25 16:08:16 2014

@author: kobrien
"""
import mysql.connector
from mysql.connector import errorcode


def open_database(config):

    print config
    
    try:
        cnx = mysql.connector.connect(**config)
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR:
            print("Something is wrong with your user name or password")
        elif err.errno == errorcode.ER_BAD_DB_ERROR:
                print("Database does not exists")
        else:
                print(err)
                
    return cnx



def create_database(cnx, dbname):
    
    try:
        cursor = cnx.cursor()
        cursor.execute(
            "CREATE DATABASE {} DEFAULT CHARACTER SET 'utf8'".format(dbname))
    except mysql.connector.Error as err:
        print("Failed creating database: {}".format(err))
        return(1)

    try:
        cnx.database = dbname    
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_BAD_DB_ERROR:
            create_database(cursor)
            cnx.database = dbname
        else:
            print(err)
            return(1)
   
    cursor.close()        
    return(0)

    
def create_table(cnx, name, tabledef):
   
   
    ddl = str("CREATE TABLE " + name +  tabledef )    
    
    print ("DDL= ")
    print (ddl)
    
    cursor = cnx.cursor()
    
    try:
  
        print("Creating table {}: ".format(name))
        cursor.execute(ddl)
    except mysql.connector.Error as err:
        if err.errno == errorcode.ER_TABLE_EXISTS_ERROR:
            print("already exists.")
            return(0)
        else:
            print(err.msg)
            return(1)
    else:
        print("OK")
        cursor.close()
        return(0)
        

        """    
    ddl = str("( CREATE TABLE " + name + " (" + 
    "  `dept_no` char(4) NOT NULL," +
    "  `dept_name` varchar(40) NOT NULL," + 
    "  PRIMARY KEY (`dept_no`), UNIQUE KEY `dept_name` (`dept_name`)" +
    " ) ENGINE=InnoDB") 
    """