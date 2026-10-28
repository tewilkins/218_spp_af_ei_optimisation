data {
  int<lower=1> n_obs;                     // Total number of observations
  int<lower=1> n_site;                    // Number of sites
  int<lower=1> n_site_pred;               // Number of site-level predictors
  int<lower=1> n_obs_pred;                // Number of observation-level predictors
  
  matrix[n_site, n_site_pred] u_site;     // Site-level predictors
  matrix[n_obs, n_obs_pred] u_obs;        // Observation-level predictors

  array[n_obs] int<lower=1, upper=n_site> site; // Site index for each observation
  array[n_obs] real<lower=0, upper=1> y; // vector of signal scores
}

parameters {
  // Slopes for static site-specific predictors
  vector[n_site_pred] beta_site;                

  // Slopes for sample-specific predictors (season, riff)
  vector[n_obs_pred] beta_obs;                

  // Random site effect:
  vector[n_site] a_site_raw;
  real<lower=0> sigma_site;
  
  // Global intercept and phi:                
  real alpha;
  real<lower=0> phi;
}

transformed parameters {
  // Non-centred Regression Slopes
  vector[n_site] a_site;

  // Non-centered transformations for hierarchical variances
  a_site = a_site_raw * sigma_site;
}

model {
  // Priors for the betas
  beta_site ~ std_normal();
  beta_obs ~ std_normal();

  // Priors for site intercepts
  a_site_raw ~ std_normal();
  sigma_site ~ student_t(3,0,1);  //
  // sigma_site ~ std_normal();  //
  alpha ~ std_normal();
  
  // Beta overdispersion:
  phi ~ lognormal(2, 0.3);
  
  // by declaring U_site_expanded and mu inside these braces, they are not saved in the model fit.
    {
    matrix[n_obs, n_site_pred] U_site_expanded = u_site[site];
    vector[n_obs] eta; // linear predictor
    vector[n_obs] mu;  // mean of the beta distribution
    eta = alpha
       + U_site_expanded * beta_site
       + u_obs * beta_obs
       + a_site[site];
    mu = inv_logit(eta);  // Transform linear predictor to (0,1) range using the inverse logit function
    y ~ beta(mu * phi, (1 - mu) * phi); // Likelihood for the observed data
  }
}

generated quantities {
  vector[n_obs] y_rep;       // Simulated replica data
  vector[n_obs] y_rep_env;   // Simulated replica data predicted using only fixed predictors
  vector[n_obs] log_lik;     // Flattened log-likelihood
  vector[n_obs] log_lik_env; // Likelihood given only fixed predictors
  vector[n_obs] p_total_out; // For calculation of full-model AUC in R
  vector[n_obs] p_env_out;   // For calculation of AUC using only fixed predictors in R
  
  {
    matrix[n_obs, n_site_pred] U_site_expanded = u_site[site];
    vector[n_obs] eta;
    vector[n_obs] eta_env; // Secondary matrix to capture pure environment effects
    vector[n_obs] mu;
    vector[n_obs] mu_env;  // Secondary matrix to capture pure environment effects

    // Environmental component only
    eta_env = alpha
            + U_site_expanded * beta_site
            + u_obs * beta_obs;
    mu_env = inv_logit(eta_env);

    // Full model
    eta = eta_env + a_site[site];
    mu = inv_logit(eta);

    for (i in 1:n_obs) {

      // Predicted mean response
      p_total_out[i] = mu[i];
      p_env_out[i] = mu_env[i];

      // Posterior predictive observations
      y_rep[i] = beta_rng(mu[i] * phi, (1 - mu[i]) * phi);
      y_rep_env[i] = beta_rng(mu_env[i] * phi, (1 - mu_env[i]) * phi);

      // Observation-level log likelihood
      log_lik[i] = beta_lpdf(y[i] | mu[i] * phi, (1 - mu[i]) * phi);
      log_lik_env[i] = beta_lpdf(y[i] | mu_env[i] * phi, (1 - mu_env[i]) * phi);

    }
  }
}
