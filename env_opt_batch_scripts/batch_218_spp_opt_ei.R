source("quick_218_spp_data_assembly_for_ou_model.R")
source("cmdstanr_functions.R")

load("~/uomShare/wergStaff/ChrisW/git-data/mwstr/impervious/sites_ei_sW_W_vars.rda")
sites_ei_sW_W_vars <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/impervious/sites_ei_sW_W_vars.rds")
sites_ei_sW_W_vars$sitecode_v12 <- sites$sitecode_v12[match(sites_ei_sW_W_vars$reach, sites$reach)]
# Calculated on water-prod with ei_vars.R 9 Sep 2026
# 1307 ei variables!  Let's just start with the 120(!) with W = Inf
ei_vars <- sites_ei_sW_W_vars # [c(grep("WInf", names(sites_ei_sW_W_vars)), which(names(sites_ei_sW_W_vars) == "sitecode_v12"))]
# And with L<32
ei_vars <- ei_vars[!grepl("L32|L64|L128",names(ei_vars)) | names(ei_vars) == "sitecode_v12"]  # down to 75
# And with sW<1600
ei_vars <- ei_vars[!grepl("sW1600|sW3200",names(ei_vars)) | names(ei_vars) == "sitecode_v12"]  # down to 65
ei_vars <- data.frame(ei_vars, ti = sites_ei_sW_W_vars$ti)
ei_var_names <- names(ei_vars)[names(ei_vars) != "sitecode_v12"]  #66


args <- commandArgs(trailingOnly = TRUE)

# If accidentally run it without an argument, default to the first model
if (length(args) == 0) {
  ei_var_to_use <- ei_var_names[1]
} else {
  ei_var_to_use <- args[1] # This captures the string you type in terminal
}

# --- Execute only the single chosen model ---
print(paste("Starting model:", ei_var_to_use))
ei <- ei_vars[,c("sitecode_v12", ei_var_to_use)]
ei <- ei[match(sites$sitecode_v12, ei$sitecode_v12),]
lei <- log(ei[,2] + 0.001)
I <- scale(lei)

# Use optimal AF
af_var_df <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_37_var_df.rds")
af <- af_var_df[match(sites$sitecode_v12,af_var_df$sitecode_v12),c("sitecode_v12","af_l1w1600")]
F <- scale(af$af_l1w1600)

new_pred_site <- as.data.frame(master_data$u_site)
# Noting that the equivalent model with the previously determined optimal AF 
# values is stored in 
# "~/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/trial_196spp_models/ifqctl_fi_qf_qi_fiq"
new_pred_site <- new_pred_site[,c("I","F","Q","Q2","C","T","L","F_I","Q_F","Q_I","F_I_Q")]

new_pred_site$I <- as.vector(I)
# I checked I and Q were equivalent to the u_matrix values
#sum(I != master_data$u_site[,colnames(master_data$u_site) == "I"])  #0
#sum(Q != master_data$u_site[,colnames(master_data$u_site) == "Q"])  #0
new_pred_site$F_I <- as.vector(F * I)
new_pred_site$Q_F <- as.vector(Q * F)
new_pred_site$Q_I <- as.vector(Q * I)
new_pred_site$F_I_Q <- as.vector(F * I * Q)

# --- Execute only the single chosen model ---
print(paste("Starting model:", ei_var_to_use))

run_218spp_model(pred_site = names(new_pred_site),
                 u_site = new_pred_site,
                 n_iterations = 800, n_chains = 4,
                 mod_code = ei_var_to_use,
                 proj_dir = "~/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/trial2_218spp_ei_opt/",
                 mod_path = "stancode/jointspp_pa_mb.stan", 
                 compile_summary = FALSE, 
                 compile_loo = TRUE)

print(paste("Finished model:", ei_var_to_use))

