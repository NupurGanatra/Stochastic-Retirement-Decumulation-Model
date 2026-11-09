library(flexsurv)
#STEP 1: DEMOGRAPHIC MODELING (SIMULATE STOCHASTIC LIFESPANS)
#-------------------------------------------------------------------------------
# Goal: Assign a realistic, individual death age to each retiree using a 
# Gompertz mortality model rather than assuming a fixed lifespan.

set.seed(50)
n=5000
alpha= 0.0001 #baseline
beta= 0.085 #rate
retirement_age= 65
additional_years <-rgompertz(n, shape = beta, rate = alpha *exp(beta * retirement_age))
death_ages<- additional_years+retirement_age
survival_years<-pmin(ceiling(additional_years),35)
head(survival_years)

# STEP 2: ECONOMIC MODELING 
#-------------------------------------------------------------------------------
# Goal: Create an N x 35 matrix of annual market return growth multipliers 
# using Geometric Brownian Motion (GBM) with log-normal drift correction.

mu<-0.065
sigma= 0.12
t=1
duration= 35

set.seed(50)
simulate_portfolio_returns<- function(n,duration,mu,sigma,t){
  drift<- (mu - 0.5*(sigma^2))*t
  Z<- matrix(rnorm(n*duration,mean=0,sd=1),nrow=n,ncol=duration)
  log_returns<- drift+ sigma*sqrt(t)*Z
  return_factors<- exp(log_returns)
  colnames(return_factors)<- paste0('Year_',1:duration)
  rownames(return_factors)<- paste0("Retiree_",1:n)
  return(return_factors)
}
set.seed(50)
R_matrix<- simulate_portfolio_returns(n,duration,mu,sigma,t)


# STEP 3: DECUMULATION ENGINE 
#-------------------------------------------------------------------------------
# Goal: Apply annual living expense withdrawals to each retiree's portfolio, 
# compound remaining assets by market returns, and track wealth over time.

decumulation<- function(R_matrix,survival_years,initial_wealth=1000000,annual_spend=40000){
  n<- nrow(R_matrix)
  duration<- ncol(R_matrix)
  wealth_matrix<- matrix(0,nrow=n,ncol=duration)
  
  wealth_matrix[, 1] <- pmax(0, (initial_wealth - annual_spend) * R_matrix[, 1])
  
  for (i in 2:duration){
    active<- survival_years>=(i-1)
    prev_wealth<- wealth_matrix[,i-1]
    new_wealth<-ifelse(active,(prev_wealth-annual_spend)*R_matrix[,i],0)
    wealth_matrix[,i]<-pmax(0,new_wealth)
    
  }
  return(wealth_matrix)
}
wealth_results<-decumulation(R_matrix,survival_years)
head(wealth_results,5)

# STEP 4: EVALUATION 
# ------------------------------------------------------------------------------
# Goal: Calculate key risk indicators: Probability of Ruin, Ruin Counts, 
# and Median Legacy Value passing to heirs at death.

#retirement plan 

retirement_plan<- function(wealth_matrix,survival_years){
  n<- nrow(wealth_matrix)
  duration<- ncol(wealth_matrix)
  
  ruin_flags<- logical(n)
  legacy_balances<- numeric(n)
  
  for(i in 1:n){
    death_year<- survival_years[i]
    path_wealth<- wealth_matrix[i,1:death_year]
    is_ruined<- any(path_wealth==0)
    ruin_flags[i]<-is_ruined
    
#legacy: what was left in the portfolio at the exact year of death?    
    if(!is_ruined){
      legacy_balances[i]<-path_wealth[death_year]
    } else {
      legacy_balances[i]<-0
    }
  }
  prob_ruin<- mean(ruin_flags)*100
  non_ruined_legacy<- legacy_balances[!ruin_flags]
  median_legacy<-median(non_ruined_legacy)
  return(list(
    probability_of_ruin = prob_ruin,
    median_legacy = median_legacy,
    ruin_count = sum(ruin_flags)
  ))

}
results_summary <- retirement_plan(wealth_results, survival_years)
results_summary

