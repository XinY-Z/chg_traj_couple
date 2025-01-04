## options ####

cpt.control <- list(
  'coupleid'='coupleid',  # couple id column name
  'partnerid'='partnerid',  # partner id column name
  'outcome'='outcome',    # outcome column name
  'similarity.type'='jaccard',  # similarity index type: jaccard, ochiai, f1, kulczynski2
  'lag'=2,  # lag for similarity index, now only support up to 2
  'method'='PELT', # method for changepoint detection: PELT, BinSeg, SegNeigh
  'distribution'='Normal',  # distribution assumption of the data
  'penalty'='Manual', # penalty for changepoint detection: Manual, AIC, BIC, MBIC, Hannan-Quinn
  'pen.value'='5*log(n)',  # penalty value, ignored if penalty is not 'manual', see ?cpt.mean
  'min.length'=1  # minimum length of the data
)
