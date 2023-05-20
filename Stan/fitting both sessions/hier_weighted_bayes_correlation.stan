

data {
  int<lower=1> nsubs; // number of subjects
  int<lower=1> ntrials; // number of subjects
  int<lower=1> sesions;
  array[ntrials, nsubs,sesions] real <lower=0, upper=1> percept; // observations
  array[ntrials, nsubs,sesions] int pred; // prediciton
  array[ntrials, nsubs,sesions] int percept_bin; // prediciton
  
  array[ntrials, nsubs,sesions] int stim; // observations
  array[ntrials, nsubs,sesions] int cues; // observations
}

parameters {
  
  array [nsubs,sesions] real <lower=0,upper=1> alpha;
  array [nsubs,sesions] real <lower=0> percept_precision;
  array [nsubs,sesions] real <lower=0> beta;
  array [nsubs,sesions] real <lower=0,upper=1> w1;
  array [nsubs,sesions] real <lower=0,upper=1> w2;

  // Group-level parameters
  array[sesions] real <lower=0> kappa_alpha;
  array[sesions] real <lower=0, upper  = 1> mu_alpha;
  array[sesions] real <lower=0,upper=1> mu_w1;
  array[sesions] real <lower=0> kappa_w1;
  array[sesions] real <lower=0,upper=1> mu_w2;
  array[sesions] real <lower=0> kappa_w2;
 // Group-level parameters
  array[sesions] real <lower=0> sd_beta;
  array[sesions] real <lower=0> sd_percept_precision;
}


transformed parameters{
  
  array[ntrials, nsubs,sesions] real <lower=0,upper=1> perceptmu; 
  array[ntrials+1, nsubs,sesions] real <lower=0,upper=1> expect;
  array[ntrials+1, nsubs,sesions] real<lower=0,upper=1>association;
  array[ntrials, nsubs,sesions] real  pe;
  
  for (sess in 1:sesions){
    
    for (s in 1:nsubs){
      
      association[1,s,sess] = 0.5;
      expect[161,s,sess] = 0.5;
    
      for (t in 1:ntrials){
        
        if(cue[t,s,sess] == 1){
            expect[t,s,sess] = association[t,s,sess];
          }else{
            expect[t,s,sess] = 1-association[t,s,sess];
          }
        
       
        perceptmu[t,s,sess] = inv_logit(w1[s,sess] * logit(stim[t,s,sess]) + w2[s,sess] * logit(expect[t,s,sess]));
        
        
        if(cue[t,s,sess] == 1){
            pe[t,s,sess] = (perceptmu[t,s,sess] - expect[t,s,sess]);
          }else{
            pe[t,s,sess] = -(perceptmu[t,s,sess] - expect[t,s,sess]);
          }
          
        association[t+1,s,sess] = association[t,s,sess] + alpha[s,sess] * pe[t,s,sess];
      }
    }
  }
}


model {
  
  for (sess in 1:sesions){
   
    for (s in 1: nsubs){
      // generating data
      for (t in 1:ntrials){
        target += beta_proportion_lpdf(percept[t,s,sess] | perceptmu[t,s,sess], percept_precision[s,sess]);
        target += bernoulli_lpmf(percept_bin[t,s,sess] | (perceptmu[t,s,sess]^beta[s,sess])/((perceptmu[t,s,sess]^beta[s,sess])+(1-perceptmu[t,s,sess])^(beta[s,sess])));
        target += bernoulli_lpmf(pred[t,s,sess] |  (expect[t,s,sess]^beta[s,sess])/((expect[t,s,sess]^beta[s,sess])+(1-expect[t,s,sess])^(beta[s,sess])));
      }
      // generating subject-level parameters
      target += beta_proportion_lpdf(alpha[s,sess] | mu_alpha[sess] , kappa_alpha[sess]);
      target += beta_proportion_lpdf(w1[s,sess] | mu_w1[sess], kappa_w1[sess]);
      target += beta_proportion_lpdf(w2[s,sess] | mu_w2[sess], kappa_w2[sess]);
  
      target += lognormal_lpdf(percept_precision[s,sess] | log(10), sd_percept_precision[sess]);
      target += lognormal_lpdf(beta[s,sess] | log(10), sd_beta[sess]);
      
  }
    
    // Hierarchical Priors
    target += beta_proportion_lpdf(mu_alpha[sess] | 0.1 , 10) ; 
    target += lognormal_lpdf(kappa_alpha[sess] | log(30),0.5); 
    
    target += beta_proportion_lpdf(mu_w1[sess] | 0.1 , 10) ; 
    target += lognormal_lpdf(kappa_w1[sess] | log(30),0.5);
    
    target += beta_proportion_lpdf(mu_w2[sess] | 0.1 , 10) ; 
    target += lognormal_lpdf(kappa_w2[sess] | log(30),0.5);
    
    target += exponential_lpdf(sd_percept_precision[sess] | 0.5);
    target += exponential_lpdf(sd_beta[sess] | 0.5);
    
  }
}

generated quantities{
  array[sesions] real <lower=0> prior_sd_precision_percept;
  array[sesions] real <lower=0> prior_sd_beta;
  
  array[sesions] real <lower=0> prior_kappa_alpha;
  array[sesions] real <lower=0, upper=1> prior_mu_alpha;

  array[sesions] real <lower=0, upper=1> prior_mu_w1;
  array[sesions] real <lower=0> prior_kappa_w1;
  
  array[sesions] real <lower=0, upper=1> prior_mu_w2;
  array[sesions] real <lower=0> prior_kappa_w2;
  
  //subject level
  
  array[nsubs,sesions] real <lower=0, upper = 1> prior_alpha;
  array[nsubs,sesions] real <lower=0> prior_precision_percept;
  array[nsubs,sesions] real <lower=0> prior_beta;
  array[nsubs,sesions] real <lower=0, upper = 1> prior_w1;
  array[nsubs,sesions] real <lower=0, upper = 1> prior_w2;
  
  //trial level:
  array[ntrials, nsubs,sesions] real <lower=0, upper  = 1> prior_painMu; 
  array[ntrials+1, nsubs,sesions] real <lower=0, upper  = 1> prior_association; 
  array[ntrials+1, nsubs,sesions] real <lower=0, upper  = 1> prior_expect;
  array[ntrials, nsubs,sesions] real prior_pe;

  array[ntrials, nsubs,sesions] real <lower=0, upper  = 1> prior_percept;
  array[ntrials, nsubs,sesions] real <lower=0, upper  = 1> prior_percept_bin;  
  array[ntrials, nsubs,sesions] real <lower=0, upper  = 1> prior_expectPain;

  array[ntrials, nsubs,sesions] real <lower=0, upper  = 1> post_percept;
  array[ntrials, nsubs,sesions] real <lower=0, upper  = 1> post_percept_bin;  
  array[ntrials, nsubs,sesions] real <lower=0, upper  = 1> post_expectPain;
  
  array[ntrials, nsubs,sesions] real log_lik;

  
  
  for(sess in 1:sesions){
    prior_mu_w1[sess] = beta_proportion_rng(0.1,10);
    prior_kappa_w1[sess] = lognormal_rng(log(30),0.5);
    
    prior_mu_w2[sess] = beta_proportion_rng(0.1,10);
    prior_kappa_w2[sess] = lognormal_rng(log(30),0.5);
    
    prior_mu_alpha[sess] = beta_proportion_rng(0.1,10);
    prior_kappa_alpha[sess] = lognormal_rng(log(30),0.5);
    
    prior_sd_percept_precision[sess] = exponential_rng(0.5);
    prior_sd_beta[sess] = exponential_rng(0.5);
    
    for (s in 1:nsubs){
      prior_alpha[s,sess] = beta_proportion_rng(prior_mu_alpha[sess] , prior_kappa_alpha[sess]);
      prior_w1[s,sess] = beta_proportion_rng(prior_mu_w1[sess] , prior_kappa_w1[sess]);
      prior_w2[s,sess] = beta_proportion_rng(prior_mu_w2[sess] , prior_kappa_w2[sess]);
      
      prior_percept_precision[s,sess] = lognormal_rng(log(10), prior_sd_percept_precision[sess]);
      prior_beta[s,sess] = lognormal_rng(log(10), prior_sd_beta[sess]);
      
  
      prior_association[1, s,sess] = 0.5;
      prior_expect[161, s,sess] = 0.5;
        
      for (t in 1:ntrials){
        
        
        if(cue[t,s,sess] == 1){
          prior_expect[t,s,sess] = prior_association[t,s,sess];
        }else{
          prior_expect[t,s,sess] = 1-prior_association[t,s,sess];
        }
        
        
        prior_perceptmu[t,s,sess] = inv_logit(prior_w1[s,sess] * logit(stim[t,s,sess]) + prior_w2[s,sess] * logit(prior_expect[t,s,sess]));
        
        
        if(cue[t,s,sess] == 1){
          prior_pe[t,s,sess] = (prior_perceptmu[t,s,sess] - prior_expect[t,s,sess]);
        }else{
          prior_pe[t,s,sess] = -(prior_perceptmu[t,s,sess] - prior_expect[t,s,sess]);
        }
    
        prior_association[t+1,s,sess] = prior_association[t,s,sess] + prior_alpha[s,sess] * prior_pe[t,s,sess];
      
      
        prior_percept[t,s,sess] = beta_proportion_rng(prior_perceptmu[t,s,sess], prior_percept_precision[s,sess]);
        
        prior_percept_bin[t,s,sess] = bernoulli_rng((prior_perceptmu[t,s,sess]^prior_beta[s,sess])/((prior_perceptmu[t,s,sess]^prior_beta[s,sess])+(1-prior_perceptmu[t,s,sess])^(prior_beta[s,sess])));
  
        prior_expectPain[t,s,sess] = bernoulli_rng((prior_expect[t,s,sess]^prior_beta[s,sess])/((prior_expect[t,s,sess]^prior_beta[s,sess])+(1-prior_expect[t,s,sess])^(prior_beta[s,sess])));
        
        
        post_percept[t,s,sess] = beta_proportion_rng(perceptmu[t,s,sess], percept_precision[s,sess]);
        
        post_percept_bin[t,s,sess] = bernoulli_rng((perceptmu[t,s,sess]^beta[s,sess])/((perceptmu[t,s,sess]^beta[s,sess])+(1-perceptmu[t,s,sess])^(beta[s,sess])));
  
        post_expectPain[t,s,sess] = bernoulli_rng((expect[t,s,sess]^beta[s,sess])/((expect[t,s,sess]^beta[s,sess])+(1-expect[t,s,sess])^(beta[s,sess])));
        
        
        log_lik[t,s,sess] = bernoulli_lpmf(percept_bin[t,s,sess] | (perceptmu[t,s,sess]^beta[s,sess])/((perceptmu[t,s,sess]^beta[s,sess])+(1-perceptmu[t,s,sess])^(beta[s,sess])))+
                       beta_proportion_lpdf(percept[t,s,sess] | perceptmu[t,s,sess], percept_precision[s,sess])+
                       bernoulli_lpmf(pred[t,s,sess] |  (expect[t,s,sess]^beta[s,sess])/((expect[t,s,sess]^beta[s,sess])+(1-expect[t,s,sess])^(beta[s,sess])));
      
      }
    }
  }
  
}