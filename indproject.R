# Ken O'Brien - Individual Project

# Program to read World Bank GDP indicators from the database.  Calculates regression
# for each country with complete data between GDP Growth versus GDP Debt
# the Regression is calculated for each country, the a Regresson for all countries is 
# calculated.  Plots for various starting total debt percentage are displayed

library(RMySQL) # will load DBI as well
library(ggplot2)
library(car) 

## open a connection to a MySQL database
con <- dbConnect(dbDriver("MySQL"), user = "root", password = "root", host='192.168.56.101', dbname = "worldbank2")

## list the tables in the database
dbListTables(con)

## load a data frame into the database, deleting any existing copy
#dfind = data("wbindicators")
d <- dbReadTable(con, "wbindicatorFull")

# get the list of countries without the Aggregate Regions
clist <- unique(subset(d, region != 'Aggregates', select = 'iso3c'))
clist2 <- split(clist, clist$iso3c)
numcountries = length(clist2)

# create a separate list of countries versus pointing to the dataframe elements
countrylist = mat.or.vec(numcountries,1)
countrylist = []
n=1
for (i in clist2) {
  country = i$iso3c
  print(country)
  countrylist[n] = country
  n=n+1
}


# reduce the dataset to only the columns we are interested in
dd <-d[c('dateyear', 'iso3c', 'NY.GDP.MKTP.KD.ZG', 'GC.DOD.TOTL.GD.ZS', 'incomeLevel')]

yearoffset = 0
maxoffsetyears=20

yearcol <- c(0:maxoffsetyears)
fit2 = mat.or.vec(numcountries,length(yearcol))
interceptvec = mat.or.vec(numcountries,1)
slopevec = mat.or.vec(numcountries,1)
n=1
for (country in countrylist) {
  #print(i)
  
  #country = str(countrylist[i])
  print(country)
  
  # create a data subset for the country of interest in the loop
  ddd <- subset(dd, iso3c == country)
  
  
  fit  <- tryCatch( { lm( GC.DOD.TOTL.GD.ZS ~ NY.GDP.MKTP.KD.ZG ,  data = ddd, na.action=na.omit) 
                     
                    
                     }, warning = function(war) {
    
                     # warning handler picks up where error was generated
                     print(paste("MY_WARNING:  ",war))
                    
                     }, error = function(err) {
                       
                       # error handler picks up where error was generated
                       print(paste("MY_ERROR:  ",err))
                       return(NA)
                                            
                                           
                     }, finally = {
                     }) # END tryCatch
  
  if (length(fit) > 1) {
    interceptvec[n] <- fit$coefficient[1]
    slopevec[n] <-fit$coefficient[2]
  } else {
    interceptvec[n] = NA
    slopevec[n] = NA
  }
   
   n = n+1
  
} # END for country in 

regressionresults = data.frame(countrylist,interceptvec,slopevec)
countryincome = unique(subset(d, region != 'Aggregates', select = c('iso3c', 'incomeLevel')))
regressresultsIncome = merge(regressionresults, countryincome, by.x = "countrylist", by.y="iso3c", all=FALSE)

t1 <- na.omit(regressionresults)

#fit <- lm( GC.DOD.TOTL.GD.ZS ~ NY.GDP.MKTP.KD.ZG ,  data = ddsub, na.action=na.omit)
allcountryfit <- lm(slopevec~interceptvec)
plot(interceptvec, slopevec, xlab="Total Debt (%GDP)", ylab="GDP Growth (%)", main="GDP Growth versus Debt")
abline(allcountryfit, col='blue')
#text(10,10, "Regression All Countries", col = "blue", adj = c(0, -.1))

t2 <- subset(t1, interceptvec > 0 & interceptvec < 200)
t2fit <- lm(t2$slopevec ~ t2$interceptvec)
abline(t2fit, col='red')
#lines(lowess(interceptvec,slopevec), col="green")

t3 <- subset(t1, interceptvec > 60 & interceptvec < 200)
t3fit <- lm(t3$slopevec ~ t3$interceptvec)
abline(t3fit, col='green')

t4 <- subset(t1, interceptvec > 100 & interceptvec < 200)
t4fit <- lm(t4$slopevec ~ t4$interceptvec)
abline(t4fit, col='purple')
#legend(cex=0.7,xjust=0, yjust=0,text.font=1, y.intersp=.5, xpd=TRUE,text.width = 40, "topright",  legend=c("All","All-Outliers", "Debt > 60%", "Debt > 100"), col=c('blue','red','green', 'purple'), title="Regression for Debt Levels")
legend( cex=0.7,"topright",  legend=c("All","All-Outliers", "Debt > 60%", "Debt > 100%"), col=c('blue','red','green', 'purple'), title="Regression for Debt Levels", bty='n', lty=1)

# Add extra space to right of plot area; change clipping to figure
#par(mar=c(5.1, 4.1, 4.1, 8.1), xpd=TRUE)

scatterplot(slopevec~interceptvec | incomeLevel, data=regressresultsIncome, 
            xlab="Total Debt (%GDP)", ylab="GDP Growth (%)", 
            main="GDP Growth by GDP Debt for various Income Levels", 
            ylim=c(-30,30),
            
            legend.plot = FALSE,
            legend.coords = "bottomleft",
            labels=row.names(regressresultsIncome))

# Add legend to top right, outside plot region
legend(cex=0.7,xjust=0, yjust=0,text.font=1, y.intersp=.5, xpd=TRUE,text.width = 40, "topright",  legend=c(sort(unique(regressresultsIncome$incomeLevel))), pch=c(1,2,3,4,5), title="Income Level Groups")
# inset=c(-0.02,.65),

# Evaluate Nonlinearity
# component + residual plot 
#crPlots(allcountryfit)
# Ceres plots 
#ceresPlots(allcountryfit)
