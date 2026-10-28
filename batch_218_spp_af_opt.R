source("quick_218_spp_data_assembly_for_ou_model.R")
source("cmdstanr_functions.R")

load("~/uomShare/wergStaff/ChrisW/git-data/mwstr/impervious/sites_ei_sW_W_vars.rda")
# Use optimal EI determined by af_opt_196_spp.R
ei <- sites_ei_sW_W_vars[,c("sitecode_v12", "ei_L2_sW40_WInf")]
ei <- ei[match(sites$sitecode_v12, ei$sitecode_v12),]
lei <- log(ei[,2] + 0.001)
I <- scale(lei)

#See bottom of af_variant_compilation_for_optimization.qmd for additional calculations
# used to compile af_var_list_229_sites.rds and af_big_var_list_229_sites.rds
afs_list <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_229_sites.rds")
# Additional af variants calculated to optimize search on second attempt
add_afs_list_1 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add1.rds")
add_afs_list_2 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add2.rds")
add_afs_list_3 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add3.rds")
afs_list <- afs_list[match(names(add_afs_list_1),names(afs_list))]
# sum(names(afs_list) != names(add_afs_list_1))
# sum(names(afs_list) != names(add_afs_list_2))
# sum(names(afs_list) != names(add_afs_list_3))
####  all zero, all good

# Restrict search to region with elpd_diff >-20 on first attempt
Ls <- c(1,2,4,6,8,10)
Ws <- c(c(400,600,800,1000,1200))  # = 30 models.
af_vars <- expand.grid(Ls, Ws)
names(af_vars) <- c("L","W")
# Add finer search variants (and extension to W = 1600 - still need to calculate L 6, and 10 for w1600 if necessary
af_vars <- rbind(af_vars, data.frame(L = c(3.75, 4, 4, 1, 2, 4, 8),
                                     W = c(625, 625, 633, rep(1600,4))))
af_vars$af_var <- paste0("af_l",af_vars$L, "w",af_vars$W)
# Construct a data_frame with the 30 variants in columns
# af_var_df <- data.frame(sitecode_v12 = names(afs_list), matrix(nrow = 223, ncol = nrow(af_vars)))
# names(af_var_df)[-1] <- af_vars$af_var
# for(s in 1:nrow(af_var_df)){
#   for(v in 1:nrow(af_vars)){
#     site_tab <- rbind(afs_list[[af_var_df$sitecode_v12[[s]]]][,c("dL","dW","af_var","af_2022")],
#                       add_afs_list_1[[af_var_df$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")],
#                       add_afs_list_2[[af_var_df$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")],
#                       add_afs_list_3[[af_var_df$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")])
# af_var_df[s,af_vars$af_var[v]] <- site_tab$af_2022[site_tab$af_var == af_vars$af_var[v]]
#   }
# }
# saveRDS(af_var_df, file = "~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_37_var_df.rds")

af_var_df <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_37_var_df.rds")
af_var_names <- names(af_var_df)[-1]

mwstr <- DBI::dbConnect(RPostgres::Postgres(),"mwstr", host = "localhost")
tf <- DBI::dbGetQuery(mwstr, paste0("SELECT reach, tf_2022 FROM cat_env WHERE reach IN ('",
                                    paste(substr(af_var_df$sitecode_v12,1,nchar(af_var_df$sitecode_v12)-1), collapse = "','"),
                                    "');"))
af_var_df$tf <- tf$tf_2022[match(substr(af_var_df$sitecode_v12,1,nchar(af_var_df$sitecode_v12)-1), tf$reach)]

args <- commandArgs(trailingOnly = TRUE)

# If accidentally run it without an argument, default to the first model
if (length(args) == 0) {
  af_var_to_use <- af_var_names[1]
} else {
  af_var_to_use <- args[1] # This captures the string you type in terminal
}

# --- Execute only the single chosen model ---
print(paste("Starting model:", af_var_to_use))

af <- af_var_df[match(sites$sitecode_v12, af_var_df$sitecode_v12), af_var_to_use]

F <- scale(af)

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
                 proj_dir = "~/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/trial2_218spp_af_opt/",
                 mod_path = "stancode/jointspp_pa_mb.stan",
                 compile_summary = FALSE,
                 compile_loo = TRUE)

print(paste("Finished model:", af_var_to_use))

