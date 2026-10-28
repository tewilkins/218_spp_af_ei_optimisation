### Function returns the following information from a cmdstanr model:

# - fit: the fitted model object
# - loo: the leave-one-out cross-validation object
# - summary: the summary of the fitted model
# - draws: the posterior draws from the fitted model

### The code requires the following inputs:

# - stanfile: the path to the Stan model file
# - data: a list containing the data to be passed to the model
# - base_name: a base name for the output files (e.g., a predictor set, model name, hyperparameter, etc.)
# - iter_warmup: number of warmup iterations (default: 1000)
# - iter_sampling: number of sampling iterations (default: 1000)
# - chains: number of chains to run (default: 4)
# - seed: random seed for reproducibility (default: 56084)
# - adapt_delta: the target acceptance rate for the sampler (cmdstanr NULL default: 0.8)
# - path: the directory path where the output files will be saved (must be supplied - no default)

#' Compile and run a CmdStanR model
compile_cmdstanr_model <- function(stanfile, data, base_name, 
                                   iter_warmup = 1000, iter_sampling = 1000, 
                                   chains = 4, seed = 56084,
                                   refresh_rate = 200,
                                   init = 2,
                                   adapt_delta = NULL,
                                   draws_path = "draws/",
                                   loo_path = "loo/",
                                   summary_path = "summary/",
                                   summary_vars = NULL,
                                   loo_var = "log_lik") {
  
  start <- Sys.time()
  print(Sys.time())
  
  # Determine cores for parallel processing
  available_cores <- parallel::detectCores()
  
  if (available_cores < 5){
    warning("Less than 5 cores detected. Consider using a machine with more cores for better performance.")
  }
  
  n_cores <- available_cores - (chains + 1)
  if (n_cores < 1) {
    n_cores <- 1
  }
  
  # Prepare model from stanfile
  model <- cmdstanr::cmdstan_model(stanfile)
  
  # Check if the model is a valid CmdStan model
  #  if (!inherits(model, "cmdstanr_model")) {
  #    stop("The provided model is not a valid CmdStan model.")
  #  }
  
  if(is.null(draws_path)) {
    stop("Draws path cannot be NULL. Please provide a valid directory path to save the output.")
  }
  
  if(is.null(loo_path)) {
    stop("Loo path cannot be NULL. Please provide a valid directory path to save the output.")
  }
  
  if(is.null(summary_path)) {
    stop("Summary path cannot be NULL. Please provide a valid directory path to save the output.")
  }
  
  # Run the model
  print(paste0("Compiling model ", paste0(base_name), "..."))
  fit <- model$sample(data = data, 
                      iter_warmup = iter_warmup, 
                      iter_sampling = iter_sampling, 
                      chains = chains, 
                      parallel_chains = chains,
                      init = init,
                      adapt_delta = adapt_delta,
                      refresh = refresh_rate,
                      show_exceptions = FALSE,
                      seed = seed)
  print(paste0("Model ", base_name, " compiled and run successfully."))
  
  
  print(Sys.time())
  print("Saving output files...")
  fit$save_output_files(dir = draws_path,
                        basename = base_name,
                        timestamp = FALSE,
                        random = FALSE)
  saveRDS(fit, file = file.path(draws_path, paste0(base_name, "_fit.rds")))
  print("Output files saved.")
  
  # extract loo
  print("Extracting LOO...")
  fit_loo <- fit$loo(variables = loo_var, r_eff = TRUE, 
                     # Go easy on the cores there fella
                     cores = n_cores)
  saveRDS(fit_loo, file = file.path(loo_path, paste0(base_name, "_loo.rds")))
  print("LOO extracted.")
  rm(fit_loo) # Remove the fit_loo object to free up memory
  gc() # Run garbage collection
  
  # Save the summary of the fit
  print("Saving fit summary...")

  fit_summary <- fit$summary(variables = summary_vars, .cores = n_cores)
  saveRDS(fit_summary, file = file.path(summary_path, paste0(base_name, "_summary.rds")))
  print("Fit summary saved.")
  
  rm(fit_summary, fit) # Remove the fit object to free up memory
  gc() # Run garbage collection
  
  end <- Sys.time()
  print(round((end - start), 2))
}