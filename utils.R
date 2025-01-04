library(data.table)
library(changepoint)
source('config.R')


## Fit changepoint models ####

model <- function(DT, control=cpt.control) {
  mod <- cpt.mean(
    data=DT[, get(control$outcome)],
    penalty=control$penalty,
    pen.value=control$pen.value,
    method=control$method,
    test.stat=control$distribution,
    minseglen=control$min.length
  )
  return(mod)
}


## mapping functions to the whole dataset ####

map <- function(DT, get, control=cpt.control) {
  #' @param DT data, must specify coupleid, partnerid, and outcome vars in config
  #' @param get what to get, 'changepoint', 'r2', or 'similarity'
  #' @param control control parameters
  
  ## get all the changepoints
  if(get=='changepoint') {
    output <- data.table(
      coupleid=factor(), 
      partnerid=factor(), 
      changepoint_loc=character()
    )
    for(i in unique(DT[, get(control$coupleid)])) {
      for(j in unique(DT[, get(control$partnerid)])) {
        if(nrow(DT[get(control$coupleid)==i & get(control$partnerid)==j]) 
           >= control$min.length*2) {
          mod <- model(
            DT[get(control$coupleid)==i & get(control$partnerid)==j], 
            control
          )
          changepoints <- cpts(mod)
          changepoints <- paste(changepoints, collapse=',')
        }
        else changepoints <- ''
        
        temp <- list(i, j, changepoints)
        output <- rbind(output, temp)
      }
    }
  }
  
  ## get all the McFadden R2
  else if(get=='r2') {
    output <- data.table(
      coupleid=factor(),
      partnerid=factor(),
      changepoint=numeric(),
      linear=numeric(),
      loglinear=numeric(),
      quad=numeric(),
      cube=numeric()
    )
    for(i in unique(DT[, get(control$coupleid)])) {
      for(j in unique(DT[, get(control$partnerid)])) {
        if(nrow(DT[get(control$coupleid)==i & get(control$partnerid)==j]) 
           >= control$min.length*2) {
          mod <- model(
            DT[get(control$coupleid)==i & get(control$partnerid)==j], 
            control
          )
          R2 <- cpt.r2(mod)
        }
        else R2 <- c('changepoint'=NA, 'linear'=NA, 'loglinear'=NA, 'quad'=NA, 'cube'=NA)
        
        temp <- c(list('coupleid'=i, 'partnerid'=j), R2)
        output <- rbind(output, temp)
      }
    }
  }
  
  ## get all the similarity indices
  else if(get=='similarity') {
    output <- data.table(
      coupleid=factor(), 
      similarity=numeric(),
      type=character()
    )
    for(i in unique(DT[, get(control$coupleid)])) {
      if(uniqueN(DT[, get(control$partnerid)]) != 2) {
        stop("Now support only dyadic data")
      }
      
      partners <- unique(DT[get(control$coupleid)==i, get(control$partnerid)])
      
      if(nrow(DT[get(control$coupleid)==i & get(control$partnerid)==partner[1]]) 
         >= control$min.length*2) {
        mod_0 <- model(
          DT[get(control$coupleid)==i & get(control$partnerid)==partners[1]], control
        )
      }
      else mod_0 <- NA
      
      if(nrow(DT[get(control$coupleid)==i & get(control$partnerid)==partner[2]]) 
         >= control$min.length*2) {
        mod_1 <- model(
          DT[get(control$coupleid)==i & get(control$partnerid)==partners[2]], control
        )
      }
      else mod_1 <- NA
      
      if(!is.na(mod_0) & !is.na(mod_1)) {
        sim <- cpt.similarity(mod_0, mod_1, control)
      }
      else sim <- NA
      
      temp <- list('coupleid'=i, 'similarity'=sim, 'type'=control$similarity.type)
      output <- rbind(output, temp)
    }
    
    if(control$lag==1) {
      output <- dcast(
        output,
        coupleid~rep(
          paste0("simil", c('_lag1', '', '_lead1')),
          uniqueN(coupleid)),
        value.var="similarity")
    }
    if(control$lag==2) {
      output <- dcast(
        output,
        coupleid~rep(
          paste0("simil", c('_lag2', '_lag1', '', '_lead1', '_lead2')), 
          uniqueN(coupleid)),
        value.var="similarity")
    }
  }
  return(output)
}


## calculate model fit, McFadden's pseudo-R2 ####
cpt.r2 <- function(model) {
  
  ## get R2 of changepoint model
  ### get log likelihood of null model
  null <- lm(model@data.set ~ 1)
  lik.null <- logLik(null)
  
  ### get log likelihood of fitted model
  dev.fit <- logLik(model)[1]
  lik.fit <- -dev.fit/2
  
  ### calcualte McFadden's R2
  r2.cpt <- 1 - lik.fit / lik.null
  
  
  ## get R2 of simple linear model
  x <- seq_along(model@data.set)
  r2.linear <- 1 - logLik(lm(model@data.set ~ x))/lik.null
  
  ## get R2 of loglinear model
  x.log <- log(x)
  r2.loglinear <- 1 - logLik(lm(model@data.set ~ x.log))/lik.null
  
  ## get R2 of quadratic model
  x2 <- x^2
  r2.quad <- 1 - logLik(lm(model@data.set ~ x2))/lik.null
  
  ## get R2 of cubic model
  x3 <- x^3
  r2.cub <- 1 - logLik(lm(model@data.set ~ x3))/lik.null
  
  R2 <- c('changepoint'=as.numeric(r2.cpt), 
          'linear'=r2.linear, 
          'loglinear'=r2.loglinear, 
          'quad'=r2.quad, 
          'cube'=r2.cub)
  R2 <- round(R2, 3)
  
  return(as.list(R2))
}


## calculate similarity of two changepoint time series ####
cpt.similarity <- function(model0, model1, control=cpt.control) {
  #' @param model0 changepoint model of partner 1
  #' @param model1 changepoint model of partner 2
  #' @param control control parameters
  #' @param print whether to print the binary time series
  
  ## extract needed variables from the input
  cpt0 <- cpts(model0)
  cpt1 <- cpts(model1)
  N <- max(length(model0@data.set), length(model1@data.set))
  type <- control$similarity.type
  lag <- control$lag
  
  ## create similarity metrics
  jaccard <- function(intsec, uni) {
    if(uni!=0) intsec/uni else .0
  }
  ochiai <- function(intsec, sum0, sum1) {
    if(sum0*sum1!=0) intsec/sqrt(sum0*sum1) else .0
  }
  kulczynski2 <- function(intsec, sum0, sum1) {
    if(sum0*sum1!=0) (intsec/sum0+intsec/sum1)/2 else .0
  }
  f1 <- function(intsec, sum0, sum1) {
    if(intsec*sum0*sum1!=0) 2*(intsec/sum0)*(intsec/sum1)/((intsec/sum0)+(intsec/sum1))
    else .0
  }
  similarity <- function(bin_0, bin_1) {
    intsec <- sum(bin_0 & bin_1, na.rm=T)
    uni <- sum(bin_0 | bin_1, na.rm=T)
    sum0 <- sum(bin_0, na.rm=T)
    sum1 <- sum(bin_1, na.rm=T)
    if(type=='jaccard') output <- jaccard(intsec, uni)
    else if(type=='ochiai') output <- ochiai(intsec, sum0, sum1)
    else if(type=='kulczynski2') output <- kulczynski2(intsec, sum0, sum1)
    else if(type=='f1') output <- f1(intsec, sum0, sum1)
    return(output)
  }
  
  if(!lag %in% c(0,1,2)) stop('Now support only at most 2-session lags')
  
  ## get similarity indices if no lag
  if(lag==0) {
    output <- similarity(bin_0, bin_1)
    return(output)
  }
  
  ## get similarity indices with lag 1
  else if(lag==1) {
    ## for lag 0
    output <- similarity(bin_0, bin_1)
    
    ## for lag +1 
    bin_1_lead <- shift(bin_1, n=1, 'lead')
    output_lead <- similarity(bin_0, bin_1_lead)
    
    ## for lag -1
    bin_1_lag <- shift(bin_1, n=1, 'lag')
    output_lag <- similarity(bin_0, bin_1_lag)
    
    outputs <- c(output_lag, output, output_lead)
    
    return(outputs)
  }
  
  ## get similarities indices with lag 2
  else if(lag==2) {
    ## for lag 0
    output <- similarity(bin_0, bin_1)
    
    ## for lag +1 
    bin_1_lead <- shift(bin_1, n=1, 'lead')
    output_lead <- similarity(bin_0, bin_1_lead)
    
    ## for lag -1
    bin_1_lag <- shift(bin_1, n=1, 'lag')
    output_lag <- similarity(bin_0, bin_1_lag)
    
    ## for lag +2
    bin_1_lead2 <- shift(bin_1, n=2, 'lead')
    output_lead2 <- similarity(bin_0, bin_1_lead2)
    
    ## for lag -2
    bin_1_lag2 <- shift(bin_1, n=2, 'lag')
    output_lag2 <- similarity(bin_0, bin_1_lag2)
    
    outputs <- c(output_lag2, output_lag, output, output_lead, output_lead2)
    
    return(outputs)
  }
}
