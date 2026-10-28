suppressPackageStartupMessages(library(cmdstanr))
# Appends the threading variable to your Stan makefile configuration
cpp_options <- list(stan_threads = TRUE)
options(cmdstanr_max_num_threads = 4)
suppressPackageStartupMessages(library(posterior))
suppressPackageStartupMessages(library(data.table))
suppressPackageStartupMessages(library(loo))

source("quick_218_spp_data_assembly_for_ou_model.R")

# Random seed to fix Stan results
proj_seed <- 12345 
set.seed(proj_seed)

u_core <- c("I","F","Q","Q2","C","T")   # and "riff","season" in u_obs, which will remain unchanged
u_opts <- c("T2","D","B","L")

# # so pred combinations to trial are:
# pred_set <- list(u_core, c(u_core, "T2"), c(u_core, "D"), c(u_core, "B"), c(u_core, "L"), 
#                  c(u_core, "T2","D"), c(u_core, "T2","B"), c(u_core, "T2","L"), 
#                  c(u_core, "D","B"), c(u_core, "D","L"), c(u_core, "B","L"), 
#                  c(u_core, "T2","D","B"), c(u_core, "T2","D","L"), c(u_core, "T2","B","L"), 
#                  c(u_core, "D","B","L"))
# 
# names(pred_set) <- c("ifqct", "ifqct2", "ifqctd", "ifqctb", "ifqctl", 
#                      "ifqct2d", "ifqct2b", "ifqct2l",
#                      "ifqctdb", "ifqctdl", "ifqctbl", 
#                      "ifqct2db", "ifqct2dl", "ifqct2bl", "ifqctdbl")

base_core <- c(u_core, "T2","L")
# so pred combinations to trial are:
pred_set <- list(c(base_core, "F_I"),
                 c(base_core, "Q_F"), c(base_core, "Q_I"),
                 c(base_core, "F_I","Q_F"), c(base_core, "Q_F","Q_I"),
                 c(base_core, "F_I","Q_I"),
                 c(base_core, "F_I","Q_F","Q_I"))
names(pred_set) <- c("ifqct2l_fi","ifqct2l_qf","ifqct2l_qi","ifqct2l_fi_qf",
                     "ifqct2l_qf_qi","ifqct2l_fi_qi","ifqct2l_fi_qf_qi")

new_base_core <-c(base_core, "F_I","Q_F","Q_I")
pred_set$"ifqct2l_fi_qf_qi_fiq" <- c(new_base_core, "F_I_Q")

args <- commandArgs(trailingOnly = TRUE)

# If accidentally run it without an argument, default to the first model
if (length(args) == 0) {
  predset_to_use <- names(pred_set)[1]
} else {
  predset_to_use <- args[1] # This captures the string you type in terminal
}

# --- Execute only the single chosen model ---
print(paste("Starting model:", predset_to_use))

run_218spp_model(pred_site = pred_set[predset_to_use][[1]],
                 n_iterations = 800, n_chains = 4,
                 mod_code = predset_to_use,
                 mod_path = "stancode/jointspp_pa_mb.stan", 
                 compile_summary = TRUE,  compile_loo = TRUE)

print(paste("Finished model:", predset_to_use))

