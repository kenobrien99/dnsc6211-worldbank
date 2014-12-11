# -*- coding: utf-8 -*-
"""
Created on Wed Oct 22 22:37:42 2014

@author: kobrien
"""

"""
#############################################################################
DNSC6211 Individual Project - World Bank data

Retrieve World Bank country and GDP Growth and Debt indicators and store to database


"""
import pandas as pd
from pandas.io import wb
from pandas.io import sql

import mysql.connector
from mysql.connector import errorcode
from sqlalchemy import create_engine
import dbFunctions as db



# database configuration parameters
config = {
  'user': 'root',
  'password': 'root',
  'host': '192.168.56.101',
  'raise_on_warnings': True,
}

indicators = { 'gdp-growth' : 'NY.GDP.MKTP.KD.ZG', 
              'surplus' : 'GC.BAL.CASH.GD.ZS', 
              'centraldebt' :'GC.DOD.TOTL.GD.ZS',
               'gpd-currentdollars' :'NY.GDP.MKTP.CD'
               }

#engine = create_engine('mysql+mysqlconnector://root:root@192.168.56.101/worldbank')

# connect to mysql instance
cnx = db.open_database(config)

#create a database
db.create_database(cnx,"worldbank2")
cnx.database = "worldbank2"

# retrieve metadata about worldbank countries
wbcountries = wb.get_countries()
wbcountries.to_sql('countries', cnx, flavor='mysql', index=True, if_exists = 'replace')


# create a table for the indicators metadata.  the to_sql method truncates data 
# the column sizes are too small
tabledef = "  (  `index` bigint(20) DEFAULT NULL, \
  `id` varchar(63) DEFAULT NULL, \
  `name` varchar(500) DEFAULT NULL, \
  `source` varchar(500) DEFAULT NULL, \
  `sourceNote` varchar(4000) DEFAULT NULL, \
  `sourceOrganization` varchar(2000) DEFAULT NULL, \
  `topics` varchar(2000) DEFAULT NULL, \
  KEY `ix_indicatorsMeta_index` (`index`) )"
db.create_table(cnx, "indicatorsMeta", tabledef)

wbindicators = wb.get_indicators()
wbindicators.to_sql('indicatorsMeta', cnx, flavor='mysql', index=True, if_exists = 'append')



# get actual indicator data
dat = wb.download(indicator=[ 'NY.GDP.MKTP.CD','NY.GDP.MKTP.KD.ZG', 'GC.BAL.CASH.GD.ZS', 'GC.DOD.TOTL.GD.ZS' ], country='all',start=1960, end=2013)
dff = dat.reset_index()

# convert year to a number and create a datatype year field
dff['year']=dff['year'].astype(int)
dff['dateyear'] = pd.to_datetime(dff['year'] , format='%Y')

dff.to_sql('wbindicators',cnx,flavor='mysql',index=True, if_exists = 'replace')

# create a joined table to get country information with the indicators
tabledef = " as ( select wbindicators.* , countries.iso3c, countries.region, countries.incomeLevel \
from wbindicators , countries \
where wbindicators.country = countries.name ) " 
db.create_table(cnx, "wbindicatorFull", tabledef ) 



# close the database connection
cnx.close()




