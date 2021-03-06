#############
##  Code of Chapter:  Predicting Stock Market Returns
#############




####### Section:  The Available Data

##
library(xts)
data(GSPC, package="DMwR2")
first(GSPC)
last(GSPC)


#### sub-section:  Reading the Data from the CSV File

##
library(xts)
GSPC <- as.xts(read.zoo("sp500.csv", header = TRUE))


#### sub-section:  Getting the Data from the Web

##
library(quantmod)
GSPC <- getSymbols("^GSPC",auto.assign=FALSE)

##
GSPC <- getSymbols("^GSPC",from="1970-01-02",to="2016-01-25",auto.assign=FALSE)

##
opts_template$set(onlyShow=list(echo=TRUE, eval=FALSE,  tidy=FALSE),
                  onlyRun=list(echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE),
                  showFig=list(fig.width=6,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.7\\textwidth"),
                  showFig2=list(fig.width=12,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.9\\textwidth"),
                  runShow=list(echo=TRUE, eval=TRUE, message=FALSE, warning=FALSE, tidy=FALSE))
library(ggplot2)
library(grid)
library(DMwR2)
library(xts)
library(quantmod)
data(GSPC, package="DMwR2")


####### Section:  Defining the Prediction Tasks


#### sub-section:  What to Predict?

##
T.ind <- function(quotes, tgt.margin = 0.025, n.days = 10) {
    v <- apply(HLC(quotes), 1, mean)
    v[1] <- Cl(quotes)[1]
    
    r <- matrix(NA, ncol = n.days, nrow = NROW(quotes))
    for (x in 1:n.days) r[, x] <- Next(Delt(v, k = x), x)
    
    x <- apply(r, 1, function(x) sum(x[x > tgt.margin | x < -tgt.margin]))
    
    if (is.xts(quotes)) xts(x, time(quotes)) else x
}

##
candleChart(last(GSPC,'3 months'),theme='white', TA=NULL)
avgPrice <- function(p) apply(HLC(p),1,mean)
addAvgPrice <- newTA(FUN=avgPrice,col=1,legend='AvgPrice')
addT.ind <- newTA(FUN=T.ind,col='red', legend='tgtRet')
addAvgPrice(on=1) 
addT.ind()

##
avgPrice <- function(p) apply(HLC(p), 1, mean) 
addAvgPrice <- newTA(FUN=avgPrice, col=1, legend='AvgPrice')
addT.ind <- newTA(FUN=T.ind, col='red', legend='tgtRet')
candleChart(last(GSPC,'3 months'), theme='white', TA=c(addAvgPrice(on=1), addT.ind()))


#### sub-section:  Which Predictors?

##
library(TTR)
myATR        <- function(x) ATR(HLC(x))[,'atr']
mySMI        <- function(x) SMI(HLC(x))[, "SMI"]
myADX        <- function(x) ADX(HLC(x))[,'ADX']
myAroon      <- function(x) aroon(cbind(Hi(x),Lo(x)))$oscillator
myBB         <- function(x) BBands(HLC(x))[, "pctB"]
myChaikinVol <- function(x) Delt(chaikinVolatility(cbind(Hi(x),Lo(x))))[, 1]
myCLV        <- function(x) EMA(CLV(HLC(x)))[, 1]
myEMV        <- function(x) EMV(cbind(Hi(x),Lo(x)),Vo(x))[,2]
myMACD       <- function(x) MACD(Cl(x))[,2]
myMFI        <- function(x) MFI(HLC(x),  Vo(x))
mySAR        <- function(x) SAR(cbind(Hi(x),Cl(x))) [,1]
myVolat      <- function(x) volatility(OHLC(x),calc="garman")[,1]

##
library(randomForest)
data.model <- specifyModel(T.ind(GSPC) ~ Delt(Cl(GSPC),k=1:10) + 
        myATR(GSPC) + mySMI(GSPC) + myADX(GSPC) + myAroon(GSPC) + 
        myBB(GSPC)  + myChaikinVol(GSPC) + myCLV(GSPC) + 
        CMO(Cl(GSPC)) + EMA(Delt(Cl(GSPC))) + myEMV(GSPC) + 
        myVolat(GSPC)  + myMACD(GSPC) + myMFI(GSPC) + RSI(Cl(GSPC)) +
        mySAR(GSPC) + runMean(Cl(GSPC)) + runSD(Cl(GSPC)))
set.seed(1234)
rf <- buildModel(data.model,method='randomForest',
                 training.per=c("1995-01-01","2005-12-30"),
                 ntree=1000, importance=TRUE)

##
ex.model <- specifyModel(T.ind(IBM) ~ Delt(Cl(IBM), k = 1:3))
data <- modelData(ex.model, data.window = c("2009-01-01",  "2009-08-10"))

##
m <- myFavouriteModellingTool(ex.model@model.formula, as.data.frame(data))

##
varImpPlot(rf@fitted.model, type = 1)

##
varImpPlot(rf@fitted.model, type = 1)

##
imp <- importance(rf@fitted.model, type = 1)
rownames(imp)[which(imp > 30)]

##
data.model <- specifyModel(T.ind(GSPC) ~ myATR(GSPC) + mySMI(GSPC) +  myADX(GSPC) + 
                           myAroon(GSPC) + myEMV(GSPC) + myVolat(GSPC) + 
                           myMACD(GSPC) + myMFI(GSPC) + mySAR(GSPC) + 
                           runMean(Cl(GSPC)) + runSD(Cl(GSPC)))


#### sub-section:  The Prediction Tasks

##
## The regression task
Tdata.train <- as.data.frame(modelData(data.model,
                                data.window=c('1970-01-02','2005-12-30')))
Tdata.eval <- na.omit(as.data.frame(modelData(data.model,
                                data.window=c('2006-01-01','2016-01-25'))))
Tform <- as.formula('T.ind.GSPC ~ .')
## The classification task
buy.thr <- 0.1
sell.thr <- -0.1
Tdata.trainC <- cbind(Signal=trading.signals(Tdata.train[["T.ind.GSPC"]],
                                             buy.thr,sell.thr),
                      Tdata.train[,-1])
Tdata.evalC <-  cbind(Signal=trading.signals(Tdata.eval[["T.ind.GSPC"]],
                                             buy.thr,sell.thr),
                      Tdata.eval[,-1])
TformC <- as.formula("Signal ~ .")


#### sub-section:  Evaluation Criteria

##
opts_template$set(onlyShow=list(echo=TRUE, eval=FALSE,  tidy=FALSE),
                  onlyRun=list(echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE),
                  showFig=list(fig.width=6,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.7\\textwidth"),
                  showFig2=list(fig.width=12,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.9\\textwidth"),
                  runShow=list(echo=TRUE, eval=TRUE, message=FALSE, warning=FALSE, tidy=FALSE))
library(ggplot2)
library(grid)
library(DMwR2)
library(xts)
library(quantmod)
data(GSPC,package="DMwR2")
load("GSPCdata.Rdata")


####### Section:  The Prediction Models


#### sub-section:  How Will the Training Data Be Used?


#### sub-section:  The Modeling Tools

##
set.seed(1234)
library(nnet)
## The first column is the target variable
norm.data <- data.frame(T.ind.GSPC=Tdata.train[[1]],scale(Tdata.train[,-1]))
nn <- nnet(Tform, norm.data[1:1000, ], size = 5, decay = 0.01, 
           maxit = 1000, linout = TRUE, trace = FALSE)
preds <- predict(nn, norm.data[1001:2000, ])

##
sigs.nn <- trading.signals(preds,0.1,-0.1)
true.sigs <- trading.signals(Tdata.train[1001:2000, "T.ind.GSPC"], 0.1, -0.1)
sigs.PR(sigs.nn,true.sigs)

##
set.seed(1234)
library(nnet)
norm.data <- data.frame(Signal=Tdata.trainC$Signal,scale(Tdata.trainC[,-1]))
nn <- nnet(Signal ~ ., norm.data[1:1000, ], size = 10, decay = 0.01, 
           maxit = 1000, trace = FALSE)
preds <- predict(nn, norm.data[1001:2000, ], type = "class")

##
sigs.PR(preds, norm.data[1001:2000, 1])

##
set.seed(1234)
library(e1071)
sv <- svm(Tform, Tdata.train[1:1000, ], gamma = 0.001, cost = 100)
s.preds <- predict(sv, Tdata.train[1001:2000, ])
sigs.svm <- trading.signals(s.preds, 0.1, -0.1)
true.sigs <- trading.signals(Tdata.train[1001:2000, "T.ind.GSPC"], 0.1, -0.1)
sigs.PR(sigs.svm, true.sigs)

##
library(kernlab)
ksv <- ksvm(Signal ~ ., Tdata.trainC[1:1000, ], C = 10)
ks.preds <- predict(ksv, Tdata.trainC[1001:2000, ])
sigs.PR(ks.preds, Tdata.trainC[1001:2000, 1])

##
library(earth)
e <- earth(Tform, Tdata.train[1:1000, ])
e.preds <- predict(e, Tdata.train[1001:2000, ])
sigs.e <- trading.signals(e.preds, 0.1, -0.1)
true.sigs <- trading.signals(Tdata.train[1001:2000, "T.ind.GSPC"],  0.1, -0.1)
sigs.PR(sigs.e, true.sigs)

##
summary(e)

##
evimp(e, trim=FALSE)

##
opts_template$set(onlyShow=list(echo=TRUE, eval=FALSE,  tidy=FALSE),
                  onlyRun=list(echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE),
                  showFig=list(fig.width=6,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.7\\textwidth"),
                  showFig2=list(fig.width=12,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.9\\textwidth"),
                  runShow=list(echo=TRUE, eval=TRUE, message=FALSE, warning=FALSE, tidy=FALSE))
library(ggplot2)
library(grid)
library(DMwR2)
library(xts)
library(quantmod)
data(GSPC)
load("GSPCdata.Rdata")


####### Section:  From Predictions into Actions


#### sub-section:  How Will the Predictions Be Used?


#### sub-section:  Trading-Related Evaluation Criteria


#### sub-section:  Putting Everything Together: A Simulated Trader

##
policy.1 <- function(signals,market,opened.pos,money,
                     bet=0.2,hold.time=10,
                     exp.prof=0.025, max.loss= 0.05
                     )
  {
    d <- NROW(market) # this is the ID of today
    orders <- NULL
    nOs <- NROW(opened.pos)
    # nothing to do!
    if (!nOs && signals[d] == 'h') return(orders)

    # First lets check if we can open new positions
    # i) long positions
    if (signals[d] == 'b' && !nOs) {
      quant <- round(bet*money/Cl(market)[d],0)
      if (quant > 0) 
        orders <- rbind(orders,
              data.frame(order=c(1,-1,-1),order.type=c(1,2,3), 
                         val = c(quant,
                                 Cl(market)[d]*(1+exp.prof),
                                 Cl(market)[d]*(1-max.loss)
                                ),
                         action = c('open','close','close'),
                         posID = c(NA,NA,NA)
                        )
                       )

    # ii) short positions  
    } else if (signals[d] == 's' && !nOs) {
      # this is the nr of stocks we already need to buy 
      # because of currently opened short positions
      need2buy <- sum(opened.pos[opened.pos[,'pos.type']==-1,
                                 "N.stocks"])*Cl(market)[d]
      quant <- round(bet*(money-need2buy)/Cl(market)[d],0)
      if (quant > 0)
        orders <- rbind(orders,
              data.frame(order=c(-1,1,1),order.type=c(1,2,3), 
                         val = c(quant,
                                 Cl(market)[d]*(1-exp.prof),
                                 Cl(market)[d]*(1+max.loss)
                                ),
                         action = c('open','close','close'),
                         posID = c(NA,NA,NA)
                        )
                       )
    }
    
    # Now lets check if we need to close positions
    # because their holding time is over
    if (nOs) 
      for(i in 1:nOs) {
        if (d - opened.pos[i,'Odate'] >= hold.time)
          orders <- rbind(orders,
                data.frame(order=-opened.pos[i,'pos.type'],
                           order.type=1,
                           val = NA,
                           action = 'close',
                           posID = rownames(opened.pos)[i]
                          )
                         )
      }

    orders
  }

##
policy.2 <- function(signals,market,opened.pos,money,
                     bet=0.2,exp.prof=0.025, max.loss= 0.05
                    )
  {
    d <- NROW(market) # this is the ID of today
    orders <- NULL
    nOs <- NROW(opened.pos)
    # nothing to do!
    if (!nOs && signals[d] == 'h') return(orders)

    # First lets check if we can open new positions
    # i) long positions
    if (signals[d] == 'b') {
      quant <- round(bet*money/Cl(market)[d],0)
      if (quant > 0) 
        orders <- rbind(orders,
              data.frame(order=c(1,-1,-1),order.type=c(1,2,3), 
                         val = c(quant,
                                 Cl(market)[d]*(1+exp.prof),
                                 Cl(market)[d]*(1-max.loss)
                                ),
                         action = c('open','close','close'),
                         posID = c(NA,NA,NA)
                        )
                       )

    # ii) short positions  
    } else if (signals[d] == 's') {
      # this is the money already committed to buy stocks
      # because of currently opened short positions
      need2buy <- sum(opened.pos[opened.pos[,'pos.type']==-1,
                                 "N.stocks"])*Cl(market)[d]
      quant <- round(bet*(money-need2buy)/Cl(market)[d],0)
      if (quant > 0)
        orders <- rbind(orders,
              data.frame(order=c(-1,1,1),order.type=c(1,2,3), 
                         val = c(quant,
                                 Cl(market)[d]*(1-exp.prof),
                                 Cl(market)[d]*(1+max.loss)
                                ),
                         action = c('open','close','close'),
                         posID = c(NA,NA,NA)
                        )
                       )
    }

    orders
  }

##
## Train and test periods
start <- 1
len.tr <- 1000
len.ts <- 500
tr <- start:(start+len.tr-1)
ts <- (start+len.tr):(start+len.tr+len.ts-1)
## getting the quotes for the testing period
data(GSPC)
date <- rownames(Tdata.train[start+len.tr,])
marketTP <- GSPC[paste(date,'/',sep='')][1:len.ts]
## learning the model and obtaining its signal predictions for the test period
library(e1071)
s <- svm(Tform, Tdata.train[tr,], cost=10,gamma=0.01)
p <- predict(s, Tdata.train[ts,])
sig <- trading.signals(p, 0.1, -0.1)
## now using the simulated trader during the testing period
t1 <- trading.simulator(marketTP, signals=sig, policy.func='policy.1',
                        policy.pars=list(exp.prof=0.05,bet=0.2,hold.time=30))

##
t1 
summary(t1)

##
tradingEvaluation(t1)  

##
plot(t1,marketTP, theme = "white",  name = "SP500")

##
plot(t1, marketTP,  theme = "white",  name = "SP500")

##
t2 <- trading.simulator(marketTP, sig, "policy.2", list(exp.prof = 0.05, bet = 0.3))
summary(t2)
tradingEvaluation(t2)

##
start <- 2000
len.tr <- 1000
len.ts <- 500
tr <- start:(start + len.tr - 1)
ts <- (start + len.tr):(start + len.tr + len.ts - 1)
data(GSPC)
date <- rownames(Tdata.train[start+len.tr,])
marketTP <- GSPC[paste(date,'/',sep='')][1:len.ts]
s <- svm(Tform, Tdata.train[tr, ], cost = 10, gamma = 0.01)
p <- predict(s, Tdata.train[ts, ])
sig <- trading.signals(p, 0.1, -0.1)
t2 <-  trading.simulator(marketTP, sig, 
                         "policy.2", list(exp.prof = 0.05, bet = 0.3))
summary(t2) 
tradingEvaluation(t2)

##
opts_template$set(onlyShow=list(echo=TRUE, eval=FALSE,  tidy=FALSE),
                  onlyRun=list(echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE),
                  showFig=list(fig.width=6,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.7\\textwidth"),
                  showFig2=list(fig.width=12,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.9\\textwidth"),
                  runShow=list(echo=TRUE, eval=TRUE, message=FALSE, warning=FALSE, tidy=FALSE))
library(ggplot2)
library(grid)
library(DMwR2)
library(xts)
library(quantmod)
data(GSPC)
load("GSPCdata.Rdata")
source("codigoExps.R")
library(performanceEstimation)
load("analysis.Rdata")


####### Section:  Model Evaluation and Selection


#### sub-section:  Monte Carlo Estimates


#### sub-section:  Experimental Comparisons

##
tradingWF <- function(form, train, test, 
                      quotes, pred.target="signals",
                      learner, learner.pars=NULL,
                      predictor.pars=NULL,
                      learn.test.type='fixed', relearn.step=30,
                      b.t, s.t,
                      policy, policy.pars,
                      trans.cost=5, init.cap=1e+06)
{
    ## obtain the model(s) and respective predictions for the test set
    if (learn.test.type == 'fixed') {  # a single fixed model
        m <- do.call(learner,c(list(form,train),learner.pars))
        preds <- do.call("predict",c(list(m,test),predictor.pars))
    } else {  # either slide or growing window strategies
        data <- rbind(train,test)
        n <- NROW(data)
        train.size <- NROW(train)
        sts <- seq(train.size+1,n,by=relearn.step)
        preds <- vector()
        for(s in sts) {  # loop over each relearn step
            tr <- if (learn.test.type=='slide') data[(s-train.size):(s-1),] 
                  else data[1:(s-1),]
            ts <- data[s:min((s+relearn.step-1),n),]
            
            m <- do.call(learner,c(list(form,tr),learner.pars))
            preds <- c(preds,do.call("predict",c(list(m,ts),predictor.pars)))
        }    
    } 
    
    ## Getting the trading signals
    if (pred.target != "signals") {  # the model predicts the T indicator
        predSigs <- trading.signals(preds,b.t,s.t)
        tgtName <- all.vars(form)[1]
        trueSigs <- trading.signals(test[[tgtName]],b.t,s.t)
    } else {  # the model predicts the signals directly
        tgtName <- all.vars(form)[1]
        if (is.factor(preds))
            predSigs <- preds
        else {
            if (preds[1] %in% levels(train[[tgtName]]))
                predSigs <- factor(preds,labels=levels(train[[tgtName]]),
                                   levels=levels(train[[tgtName]]))
            else 
                predSigs <- factor(preds,labels=levels(train[[tgtName]]),
                                   levels=1:3)
        }
        trueSigs <- test[[tgtName]]
    }

    ## obtaining the trading record from trading with the signals
    date <- rownames(test)[1]
    market <- get(quotes)[paste(date,"/",sep='')][1:length(preds),]
    tradeRec <- trading.simulator(market,predSigs,
                                  policy.func=policy,policy.pars=policy.pars,
                                  trans.cost=trans.cost,init.cap=init.cap)
    
    return(list(trueSigs=trueSigs,predSigs=predSigs,tradeRec=tradeRec))
}

##
tradingEval <- function(trueSigs,predSigs,tradeRec,...) 
{
    ## Signals evaluation
    st <- sigs.PR(predSigs,trueSigs)
    dim(st) <- NULL
    names(st) <- paste(rep(c('prec','rec'),each=3),c('s','b','sb'),sep='.')
    
    ## Trading record evaluation
    tradRes <- tradingEvaluation(tradeRec)
    return(c(st,tradRes))
}

##
library(performanceEstimation)
library(e1071)
library(earth)
library(nnet)
LEARNERS <- c('svm','earth','nnet')
EST.TASK <- EstimationTask(method=MonteCarlo(nReps=20,
                                             szTrain=2540,szTest=1270,
                                             seed=1234),
                           evaluator="tradingEval")
VARS <- list()

VARS$svm <- list(learner.pars=list(cost=c(10,50,150),
                                   gamma=c(0.01,0.05)))
VARS$earth <- list(learner.pars=list(nk=c(10,17),
                                     degree=c(1,2),
                                     thresh=c(0.01,0.001)))
VARS$nnet <-  list(learner.pars=list(linout=TRUE, trace=FALSE,
                                     maxit=750,
                                     size=c(5,10),
                                     decay=c(0.001,0.01,0.1)))

VARS$learning <- list(learn.test.type=c("fixed","slide","grow"), relearn.step=120)
VARS$trading  <- list(policy=c("policy.1","policy.2"),
                     policy.pars=list(bet=c(0.2,0.5),exp.prof=0.05,max.loss=0.05),
                     b.t=c(0.01,0.05),s.t=c(-0.01,-0.05))

## Regression (forecast T indicator) Workflows
for(lrn in LEARNERS) {
    objName <- paste(lrn,"res","regr",sep="_")
    assign(objName,
           performanceEstimation(PredTask(Tform,Tdata.train,"SP500"),
                                 do.call("workflowVariants",
                                         c(list("tradingWF",
                                                varsRootName=paste0(lrn,"Regr"),
                                                quotes="GSPC",
                                                learner=lrn,
                                                pred.target="indicator"),
                                           VARS[[lrn]],
                                           VARS$learning,
                                           VARS$trading)
                                         ),
                                 EST.TASK,
                                 cluster=TRUE) # for parallel computation
           )
    save(list=objName,file=paste(objName,'Rdata',sep='.'))
}

## Specific settings to make nnet work as a classifier
VARS$nnet$learner.pars$linout <-  FALSE
VARS$nnet$predictor.pars <-  list(type="class")

## Classification (forecast signal) workflows
for(lrn in c("svm","nnet")) { # only these because MARS is only for regression
    objName <- paste(lrn,"res","class",sep="_")
    assign(objName,
           performanceEstimation(PredTask(TformC,Tdata.trainC,"SP500"),
                                 do.call("workflowVariants",
                                         c(list("tradingWF",
                                                varsRootName=paste0(lrn,"Class"),
                                                quotes="GSPC",
                                                learner=lrn,
                                                pred.target="signals"),
                                           VARS[[lrn]],
                                           VARS$learning,
                                           VARS$trading)
                                         ),
                                 EST.TASK,
                                 cluster=TRUE) # for parallel computation
           )
    save(list=objName,file=paste(objName,'Rdata',sep='.'))
}


#### sub-section:  Results Analysis

##
load("svm_res_regr.Rdata")
load("nnet_res_regr.Rdata")
load("earth_res_regr.Rdata")
load("svm_res_class.Rdata")
load("nnet_res_class.Rdata")
allResults <- mergeEstimationRes(svm_res_regr, earth_res_regr, nnet_res_regr, 
                                 svm_res_class, nnet_res_class,
                                 by="workflows")
rm(svm_res_regr, earth_res_regr, nnet_res_regr, svm_res_class, nnet_res_class)

##
tgtStats <- c('NTrades','prec.sb','Ret','RetOverBH','PercProf',
              'MaxDD','SharpeRatio')
toMax <- c(rep(TRUE,5),FALSE,TRUE)
rankWorkflows(subset(allResults,
                     metrics=tgtStats,
                     partial=FALSE),
              top=3,
              maxs=toMax)

##
getWorkflow("svmRegr.v138",analysisSet)

##
best <- rankWorkflows(subset(allResults,
                     metrics=tgtStats,
                     partial=FALSE),
              top=100,
              maxs=toMax)
bestWFs <- unique(as.vector(sapply(best$SP500,function(x) x$Workflow)))
analysisSet <- subset(allResults, workflows=bestWFs, partial=FALSE)
rm(allResults)

##
(tps <- topPerformers(subset(analysisSet,metrics=tgtStats,partial=FALSE),
                      maxs=toMax))

##
summary(subset(analysisSet,
               workflows=tps$SP500[c("prec.sb","Ret","PercProf","MaxDD"),
                   "Workflow"],
               metrics=tgtStats[-c(1,4,7)],
               partial=FALSE))

##
ms <- metricsSummary(subset(analysisSet,
                            metrics=c("NTrades","Ret","PercProf"),
                            partial=FALSE),
                     summary="median")[["SP500"]]
candidates <- subset(analysisSet,
                     workflows=colnames(ms)[which(ms["NTrades",] > 120)],
                     partial=FALSE)
ms <- metricsSummary(subset(candidates,
                            metrics=c("Ret","PercProf"),
                            partial=FALSE),
                     summary="median")[["SP500"]]
(sms <- apply(ms,1,function(x) names(x[order(x,decreasing=TRUE)][1:15])))
(winners <- unique(c(intersect(sms[,1],sms[,2]),sms[1:3,1],sms[1:3,2])))
winnersResults <- subset(analysisSet,
                         metrics=tgtStats,workflows=winners,
                         partial=FALSE)

##
p <- pairedComparisons(winnersResults,baseline="nnetRegr.v200",maxs=toMax)
p$Ret$WilcoxonSignedRank.test

##
p <- pairedComparisons(winnersResults,"nnetRegr.v175",maxs=toMax)
p$MaxDD$WilcoxonSignedRank.test

##
sds <- signifDiffs(p,p.limit=0.05,metrics="MaxDD")
sds$MaxDD$WilcoxonSignedRank.test$SP500

##
getWorkflow("nnetRegr.v200", winnersResults)
getWorkflow("nnetRegr.v175", winnersResults)

##
opts_template$set(onlyShow=list(echo=TRUE, eval=FALSE,  tidy=FALSE),
                  onlyRun=list(echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE),
                  showFig=list(fig.width=6,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.7\\textwidth"),
                  showFig2=list(fig.width=12,fig.height=6,echo=FALSE, eval=TRUE, message=FALSE, warning=FALSE,out.width="0.9\\textwidth"),
                  runShow=list(echo=TRUE, eval=TRUE, message=FALSE, warning=FALSE, tidy=FALSE))
library(ggplot2)
library(grid)
library(DMwR2)
library(xts)
library(quantmod)
library(performanceEstimation)
data(GSPC)
load("GSPCdata.Rdata")
source("codigoExps.R")
load("analysis.Rdata")
library(e1071)
library(nnet)
library(earth)


####### Section:  The Trading System


#### sub-section:  Evaluation of the Final Test Data

##
set.seed(1234)
data <- tail(Tdata.train, 2540) # the last 10 years of the training dataset
results <- list()
wfsOut <- list()
for (name in winners) {
    sys <- getWorkflow(name, analysisSet)
    wfsOut[[name]] <- runWorkflow(sys, Tform, data, Tdata.eval)
    results[[name]] <- do.call("tradingEval",wfsOut[[name]])
}
results <- t(as.data.frame(results))

##
results[, c("NTrades","Ret","RetOverBH","PercProf","MaxDD")]

##
getWorkflow("nnetRegr.v203", analysisSet)

##
date <- rownames(Tdata.eval)[1]
market <- GSPC[paste(date, "/", sep = "")][1:nrow(Tdata.eval), ]
plot(wfsOut[["nnetRegr.v203"]]$tradeRec, market, 
     theme = "white", name = "SP500 - final test")

##
library(PerformanceAnalytics)
equityWF <- as.xts(wfsOut[["nnetRegr.v203"]]$tradeRec@trading$Equity)
rets <- Return.calculate(equityWF)

##
chart.CumReturns(rets, main="Cumulative returns of the workflow", ylab = "returns")

##
chart.CumReturns(rets, main="Cumulative returns of the strategy", ylab="returns")

##
yearlyReturn(equityWF)

##
plot(100*yearlyReturn(equityWF), 
     main='Yearly percentage returns of the trading system')

##
plot(100*yearlyReturn(equityWF), main='Yearly percentage returns of the trading system')

##
table.DownsideRisk(rets)


#### sub-section:  An Online Trading System
