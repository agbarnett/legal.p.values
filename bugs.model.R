# bugs.model.R
# use winbugs to estimate probability of wrong answer
# January 2018
library(car) # for logit
library(R2WinBUGS)
library(ggplot2)
library(reshape2)

# get the data
load('Comments.RData') # from extract.pdf.R
# sensitivity analysis with case 001
#data = subset(data, case!=1)

# write the bugs code
model.file = 'bugs.logistic.txt'
bugs = file(model.file, 'w')
cat('model{
    for (i in 1:N){
      answer[i] ~ dbern(p[i])
      logit(p[i]) <- alpha + beta.c[case[i]]
    }
    alpha ~ dnorm(0, 0.001)
    for (k in 1:M){ # random effect for case
      beta[k] ~ dnorm(0, tau.case)
      beta.c[k] <- beta[k] - mu.beta
    }
    mu.beta <- mean(beta[1:M])
    tau.case ~ dgamma(1, 1)
# probability
    logit(pr) <- alpha 
}\n', file=bugs)
close(bugs)

# random data as a check of the model
random.data = FALSE # use random data or not
if(random.data==TRUE){
  N = 1000
  intercept = 0.1 # overall probability of correct
  case = round(runif(min=1, max=20, n=N))
  betas = rnorm(mean=0, sd=0.02, n=max(case)) # random differences between cases
  betas = betas - mean(betas) # ensure they are on zero
  answer = rep(NA, N)
  for (k in 1:N){
   p = intercept + betas[case[k]]   
   answer[k] = c('Incorrect','Correct')[rbinom(prob=p, size=1, n=1)+1]
  }
  data = data.frame(answer=answer, case=case)
}

# prepare the data for WinBUGS
case = as.numeric(as.factor(data$case)) # unique case number
M = max(case) # number of cases
N = nrow(data)
bdata = list(N = N, M = M, case=case, answer=as.numeric(data$answer=='Correct'))
# initial values (two identical sets); starting probability centred on unadjusted probability
inits = list(alpha=logit(45/154), beta=rep(0, M), tau.case=1) 
inits = rep(list(inits), 2)

# run BUGS (takes a few minutes)
parms = c('alpha','tau.case','pr','beta.c')
thin = 3 # thin samples by 3
MCMC = 5000 # number of samples after burn in and thin
bugs.results =  bugs(data=bdata, inits=inits, parameters=parms, model.file=model.file,
                     n.chains=2, n.iter=MCMC*thin*2, debug=FALSE, n.thin=thin, DIC=FALSE,
                     bugs.directory="C:/Program Files/WinBUGS14/")
bugs.results$summary

# key result: probability and 95% CI
pr = bugs.results$summary[grep('pr', rownames(bugs.results$summary)), c(1,3,7)]

# plot chains
to.plot = melt(bugs.results$sims.array)
names(to.plot) = c('MCMC','chain','variable','value')
index = grep('alpha|tau', to.plot$variable) # select chains to plot (not beta, too many)
to.plot.chains = to.plot[index,]
chain.plot = ggplot(data=to.plot.chains, aes(x=MCMC, y=value, col=factor(chain)))+
  geom_line()+
  scale_color_manual(name=NULL, values=2:3)+
  facet_wrap(~variable, scales='free_y')+
  theme_bw()+
  theme(legend.position = 'none')

# distributions (two chains combined)
index = grep('alpha|tau|pr', to.plot$variable) # select chains to plot (not beta, too many)
to.plot.dist = to.plot[index,]
dist.plot = ggplot(data=to.plot.dist, aes(x=value))+
  geom_histogram(fill='light blue', bins=20)+
  facet_wrap(~variable, scales='free')+
  theme_bw()+
  theme(legend.position = 'none')

# save for easy loading into Rmd
bugs.summary = bugs.results$summary[, c(1,3,7)] # mean and 95% CI
#outfile = 'Bugs.results.without001.RData'
outfile = 'Bugs.results.RData'
save(pr, MCMC, thin, bugs.summary, chain.plot, dist.plot, file=outfile)
