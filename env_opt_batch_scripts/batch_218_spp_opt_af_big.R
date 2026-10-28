source("quick_218_spp_data_assembly_for_ou_model.R")
source("cmdstanr_functions.R")

load("~/uomShare/wergStaff/ChrisW/git-data/mwstr/impervious/sites_ei_sW_W_vars.rda")
# Use optimal EI determined by af_opt_196_spp.R
ei <- sites_ei_sW_W_vars[,c("sitecode_v12", "ei_L2_sW40_WInf")]
ei <- ei[match(sites$sitecode_v12, ei$sitecode_v12),]
lei <- log(ei[,2] + 0.001)
I <- scale(lei)

af_vars <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_big_list_229_sites.rds")
af_var_names <- af_vars[[1]][1:3]

args <- commandArgs(trailingOnly = TRUE)

# If accidentally run it without an argument, default to the first model
if (length(args) == 0) {
  af_var_to_use <- af_var_names$af_var[1]
} else {
  af_var_to_use <- args[1] # This captures the string you type in terminal
}

# --- Execute only the single chosen model ---
print(paste("Starting model:", af_var_to_use))
af <- data.frame(sitecode = names(af_vars),
                 af_2022 = unlist(lapply(af_vars, subset, 
                                         af_var == af_var_to_use, select = af_2022)))
af <- af[match(sites$sitecode_v12, af$sitecode),]
F <- scale(af$af_2022)

new_pred_site <- as.data.frame(master_data$u_site)
# Noting that the equivalent model with the previously determined optimal AF 
# values is stored in 
# "~/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/trial_196spp_models/ifqctl_fi_qf_qi_fiq"
new_pred_site <- new_pred_site[,c("I","F","Q","Q2","C","T","T2","L","F_I","Q_F","Q_I","F_I_Q")]

new_pred_site$I <- as.vector(I)
new_pred_site$F <- as.vector(F)
# I checked I and Q were equivalent to the u_matrix values
#sum(I != master_data$u_site[,colnames(master_data$u_site) == "I"])  #0
#sum(Q != master_data$u_site[,colnames(master_data$u_site) == "Q"])  #0
new_pred_site$F_I <- as.vector(F * I)
new_pred_site$Q_F <- as.vector(Q * F)
new_pred_site$Q_I <- as.vector(Q * I)
new_pred_site$F_I_Q <- as.vector(F * I * Q)

# --- Execute only the single chosen model ---
print(paste("Starting model:", af_var_to_use))

run_218spp_model(pred_site = names(new_pred_site),
                 u_site = new_pred_site,
                 n_iterations = 800, n_chains = 4,
                 mod_code = af_var_to_use,
                 proj_dir = "~/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/trial2_218spp_af_big_opt/",
                 mod_path = "stancode/jointspp_pa_mb.stan", 
                 compile_summary = FALSE, 
                 compile_loo = TRUE)

print(paste("Finished model:", af_var_to_use))

