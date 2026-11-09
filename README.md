# Stochastic-Retirement-Decumulation-Model
A simulation of retirement withdrawals under uncertain lifespans and uncertain market returns. It estimates how likely a retiree is to run out of money before death, and how much is left at death. Built in R.

## Question
For a cohort of retirees drawing a fixed annual income from an investment portfolio, what is the probability that the portfolio is exhausted before death, and what residual value (legacy) remains at death, given uncertainty in both individual lifespans and investment returns?

## Method
The script (Stochastic_Retirement_Decumulation_Modeling.R) has four steps.

## Step 1: Lifespans. Each of 5,000 retirees gets a random age at death from a Gompertz mortality model, with hazard

- h(x) = alpha * exp(beta * x)

- Lifetimes are drawn conditional on being alive at the retirement age of 65, using rgompertz(shape = beta, rate = alpha * exp(beta * 65)). Lifetimes are rounded up to whole years and capped at 35 years of retirement.

## Step 2: Market returns. Annual return factors come from geometric Brownian motion with the log-normal drift correction:

- return factor = exp( (mu - 0.5 * sigma^2) * t + sigma * sqrt(t) * Z ),  Z ~ N(0, 1)
  
- This gives a 5,000 x 35 matrix, one row per retiree and one column per year.

## Step 3: Decumulation. 
- Each year, a retiree who is still alive withdraws the annual spend, and the remaining portfolio is multiplied by that year's return factor.
- 
- The portfolio cannot go below zero.

## Step 4: Evaluation. For each retiree, the model checks whether the portfolio hit zero at any point up to the year of death. 
- It reports the probability of ruin, the number of ruined retirees, and the median legacy.

## Parameters
Parameter	Value
- Number of retirees	5,000
- Retirement age	65
- Gompertz alpha (baseline hazard)	0.0001
- Gompertz beta (growth of mortality with age)	0.085
- Maximum horizon	35 years
- Mean annual return (mu)	6.5%
- Annual volatility (sigma)	12%
- Initial pot	$1,000,000
- Annual withdrawal	$40,000 (4% of the initial pot)

## Gompertz parameters are illustrative and were not fitted to a life table.

## Assumptions
- The withdrawal is a fixed $40,000 a year, taken at the start of each year, with no adjustment for inflation.
- The portfolio is a single asset with independent yearly returns. There are no fees or taxes.
- Each retiree has their own independent market path, so the result is the probability that an individual retiree's portfolio runs out. It is not the ruin probability of a pooled fund.
- Ruin means the portfolio reaches zero before death. Legacy is the portfolio at the year of death, and it is zero for ruined retirees.
- The median legacy is calculated over retirees who were not ruined.
- There is no other income, no annuity, and no difference in mortality between men and women.

## Results
Measure	Value
Probability of ruin=	0.58
Number of ruined retirees (out of 5,000)	= 29
Median legacy (non-ruined retirees)	= 1285808

## Observations
- The starting withdrawal rate is 4% of the portfolio and the mean return is 6.5%, so on average the portfolio grows faster than it is drawn down. Ruin is rare, and the median legacy is 1285808.
- Ruin happens mainly to retirees who live a long time and experience poor returns early in retirement (sequence-of-returns risk), because early losses leave less capital to recover while withdrawals continue.
- This is a mild scenario. Higher spending, lower returns, higher volatility or inflation-linked withdrawals would all raise the probability of ruin.

## Limitations
- Geometric Brownian motion has no fat tails, so it understates the chance of severe market crashes.
- The portfolio is a single asset, not a diversified multi-asset portfolio.
- The withdrawal does not rise with inflation.
- The Gompertz parameters are not fitted to a real mortality table.
- Only one withdrawal rule (a fixed amount) is modelled.
