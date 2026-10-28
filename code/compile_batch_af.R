load("~/uomShare/wergStaff/ChrisW/git-data/mwstr/impervious/sites_ei_sW_W_vars.rda")
# Use optimal EI determined by af_opt_196_spp.R
ei <- sites_ei_sW_W_vars[,c("sitecode_v12", "ei_L2_sW40_WInf")]
ei <- ei[match(sites$sitecode_v12, ei$sitecode_v12),]
lei <- log(ei[,2] + 0.001)
I <- scale(lei)

#See bottom of af_variant_compilation_for_optimization.qmd for additional calculations 
# # First broad search of 132 sites (with 97 sites added later...)
# load("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_add.rda")
# af_var_list_97 <- af_var_list
# load("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list.rda")
# af_var_list <- c(af_var_list, af_var_list_97)
# # I was thinking that was broader than the search in afs_list below, but it's not.  So not worth pursuing further.

af_var_list <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_229_sites.rds")
af_var_list_add <- get(load("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_add.rda"))

# used to compile af_var_list_229_sites.rds and af_big_var_list_229_sites.rds 
afs_list <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_229_sites.rds")
# Additional af variants calculated to optimize search on second attempt
add_afs_list_1 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add1.rds")
add_afs_list_2 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add2.rds")
add_afs_list_3 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add3.rds")
add_afs_list_4 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add4.rds")
add_afs_list_5 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add5.rds")
add_afs_list_6 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add6.rds")

# Create a dataframe using af_2022 for each site (as rows) and each af_var (as columns):


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
#                       add_afs_list_4[[af_var_df$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")])
#                       add_afs_list_5[[af_var_df$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")])
# af_var_df[s,af_vars$af_var[v]] <- site_tab$af_2022[site_tab$af_var == af_vars$af_var[v]]
#   }
# }
# saveRDS(af_var_df, file = "~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_37_var_df.rds")
af_var_df <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_37_var_df.rds")

# add 4 and 5
Ls <- c(1,2,4,8)
Ws <- c(c(1400,1800))  # = 30 models.
af_vars <- expand.grid(Ls, Ws)
names(af_vars) <- c("L","W")
af_vars$af_var <- paste0("af_l",af_vars$L, "w",af_vars$W)
af_var_add_df <- data.frame(sitecode_v12 = names(afs_list), matrix(nrow = 223, ncol = nrow(af_vars)))
names(af_var_add_df)[-1] <- af_vars$af_var
for(s in 1:nrow(af_var_add_df)){
  for(v in 1:nrow(af_vars)){
    site_tab <- rbind(add_afs_list_4[[af_var_add_df$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")],
                      add_afs_list_5[[af_var_add_df$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")])
    af_var_add_df[s,af_vars$af_var[v]] <- site_tab$af_2022[site_tab$af_var == af_vars$af_var[v]]
  }
}

af_var_df <- cbind(af_var_df, af_var_add_df[match(af_var_df$sitecode_v12, af_var_add_df$sitecode_v12),])

af_var_list_4 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add4.rds")
af_var_list_5 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add5.rds")
af_var_list_6 <- readRDS("~/uomShare/wergStaff/ChrisW/git-data/mwstr/forest_cover/af_var_list_223_sites_add6.rds")
af_vars_5 <- c(af_var_list_4[[1]]$af_var,af_var_list_5[[1]]$af_var,af_var_list_6[[1]]$af_var)
af_var_df_5 <- data.frame(sitecode_v12 = names(af_var_list_5), matrix(nrow = 223, ncol = length(af_vars_5)))
names(af_var_df_5)[-1] <- af_vars_5
for(s in 1:nrow(af_var_df_5)){
  for(v in 1:length(af_vars_5)){
    site_tab <- rbind(af_var_list_4[[af_var_df_5$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")],
                      af_var_list_5[[af_var_df_5$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")],
                      af_var_list_6[[af_var_df_5$sitecode_v12[s]]][,c("dL","dW","af_var","af_2022")])
    af_var_df_5[s,af_vars_5[v]] <- site_tab$af_2022[site_tab$af_var == af_vars_5[v]]
  }
}

af_var_df <- cbind(af_var_df, af_var_df_5[match(af_var_df$sitecode_v12, af_var_df_5$sitecode_v12),-1])
# The above creates some duplicate (and equivalent - I checked) column names
af_var_df <- af_var_df[,!duplicated(names(af_var_df))]

af_var_names <- names(af_var_df)[-1]

mwstr <- DBI::dbConnect(RPostgres::Postgres(), dbname = "mwstr", host = "localhost",
                        port = 5432, user = "readonly", password = "reachcode_42")

tf <- DBI::dbGetQuery(mwstr, paste0("SELECT reach, tf_2022 FROM cat_env WHERE reach IN ('",
                                    paste(substr(af_var_df$sitecode_v12,1,nchar(af_var_df$sitecode_v12)-1), collapse = "','"),
                                    "');"))
af_var_df$tf <- tf$tf_2022[match(substr(af_var_df$sitecode_v12,1,nchar(af_var_df$sitecode_v12)-1), tf$reach)]
