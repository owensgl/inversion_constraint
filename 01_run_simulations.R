
################################################################################
# create and launch inversion simulations for a range of parameter combinations
# KMS Oct 2021
################################################################################


library("tidyverse")
library("parallel")
library("inline")
options(scipen = 999)


# this function launches a slim script (and replicates) with the given parameters
# parameters:
# model params - list, a list of model parameter combinations to pass to the slim scripts
# sim_prefix - string, prefix for the launcher scripts (either '3pop' or 'clim_change')
# n_reps - integer, number of replicate sims to launch for reach parameter combination
# dryrun - logical, instead of launching the sims, just print out the launch commands (for checking purposes)
# array - should the slims be launched via SLURM job arrays, or just as individual jobs?

# delete all previous data?

remove_previous_data <- function(user_input) {
  
  if(user_input == 'y'){
    
    print('Removing all previous data...')
    unlink("tmp", recursive = TRUE)
    dir.create("tmp")
    unlink("data/slim_output", recursive = TRUE)
    dir.create("data/slim_output")
    dir.create("data/slim_output/fitness")
    dir.create("data/slim_output/haplotypes")
    
    
  } else{
    print('Leaving previous data intact!')
  }
  
}

remove_previous_data('n')


launch_slim_job <- function(model_params, sim_prefix, out_folder, n_reps = NULL, dryrun = FALSE, array = FALSE){
  
  
  # check if dirs exist, create them if not
  if(!dir.exists(out_folder)){
    dir.create(out_folder)
  } 
  
  # all the parameter flags to pass to the slim launcher script
  model_params$out_folder <- out_folder
  
  param_flags <- c("migrate", "popsi", "npops", "invssup", "sadaptive", "mutrate", 
                   "recombrate", "ndivselloci", "outfold")
  
  param_string <- data.frame(flag = param_flags, param = unlist(model_params)) %>%
    mutate(full_flag = paste(flag, param, sep ="=")) %>%
    pull(full_flag)
  
  param_string <- paste(param_string, collapse = " ")
  
  if (!array){
    
    param_string <- param_string %>% gsub("[a-z]+=", "", .)
    
    if(dryrun){
      
      print(paste0("sbatch scripts/", sim_prefix, "_run_slim_sim.sh ", param_string))
      
    } else{
      
      system(paste0("sh scripts/", sim_prefix, "_run_slim_sim.sh ", param_string))
      
    }
    
  } else if (array){
    
    array_string = paste0("--array=0-", n_reps - 1)
    
    if(dryrun){
      
      print(paste0("sbatch ", array_string, " scripts/", sim_prefix, "_run_slim_sim_array.sh ", param_string))
      
    } else{
      
      system(paste0("sbatch ", array_string, " scripts/", sim_prefix, "_run_slim_sim_array.sh ", param_string))
      
    }
    
  }
  
  
  
}

####################################################
# create parameter combos and launch jobs
####################################################

# define the range of parameter values

# migration rate
migrate_values <- c(0.1, 0.05, 0.01)

# population size
popsize_values <- c(2500)

# number of populations
npops_values <- c(3)

# inversions suppress recombination (y/n)
invssup_values <- c(0, 1)

# selection coeffiecients for local adaptation alleles
sadaptive_values <- c(0.1, 0.05, 0.01)

# mutation rate
mutationrate_values <- c(0)

# recombination rate for all loci
recombrate_values <- c(1e-2)

# number of diveregently selected loci (2-50, or 100)
# current just one setting
n_div_sel_loci_values <- c(100)

# all possible combinations of parameters
# bless u expand.grid
param_combos <- expand.grid(migrate_values, popsize_values, npops_values, 
                            invssup_values, sadaptive_values, mutationrate_values, recombrate_values, n_div_sel_loci_values)

# number of replicates per parameter combination
n_reps <- 100
dry_run <- FALSE
array <- TRUE

for (i in 1:nrow(param_combos)){
  
  migration_rate <- param_combos[i,][,1]
  popsize <- param_combos[i,][,2]
  npops <- param_combos[i,][,3]
  invssup <- param_combos[i,][,4]
  sadpative <- param_combos[i,][,5]
  mutationrate <- param_combos[i,][,6]
  recombrate <- param_combos[i,][,7]
  ndivselloci <- param_combos[i,][,8]
  
  model_params <- mget(c("migration_rate", "popsize", "npops", "invssup", "sadpative",
                         "mutationrate", "recombrate", "ndivselloci"))
  
  out_folder <- "data/slim_output"
  
  
  launch_slim_job(model_params, sim_prefix = "novel_environment_polygenic", out_folder, n_reps = n_reps, dryrun = dry_run, array = array)
  Sys.sleep(0.1)
}


# for (i in 1:nrow(param_combos)){
#   
#   migration_rate <- param_combos[i,][,1]
#   popsize <- param_combos[i,][,2]
#   npops <- param_combos[i,][,3]
#   invssup <- param_combos[i,][,4]
#   sadpative <- param_combos[i,][,5]
#   mutationrate <- param_combos[i,][,6]
#   recombrate <- param_combos[i,][,7]
#   ndivselloci <- param_combos[i,][,8]
#   
#   model_params <- mget(c("migration_rate", "popsize", "npops", "invssup", "sadpative",
#                          "mutationrate", "recombrate", "ndivselloci"))
#   
#   out_folder <- "data/slim_output"
#   
#   
#   launch_slim_job(model_params, sim_prefix = "novel_environment", out_folder, n_reps = n_reps, dryrun = dry_run, array = array)
#   Sys.sleep(0.1)
# }



# # number of populations
# npops_values <- c(2)
# 
# # all possible combinations of parameters
# # bless u expand.grid
# param_combos <- expand.grid(migrate_values, popsize_values, npops_values, 
#                             invssup_values, sadaptive_values, mutationrate_values, recombrate_values, n_div_sel_loci_values)
# 
# 
# for (i in 1:nrow(param_combos)){
#   
#   migration_rate <- param_combos[i,][,1]
#   popsize <- param_combos[i,][,2]
#   npops <- param_combos[i,][,3]
#   invssup <- param_combos[i,][,4]
#   sadpative <- param_combos[i,][,5]
#   mutationrate <- param_combos[i,][,6]
#   recombrate <- param_combos[i,][,7]
#   ndivselloci <- param_combos[i,][,8]
#   
#   model_params <- mget(c("migration_rate", "popsize", "npops", "invssup", "sadpative", 
#                          "mutationrate", "recombrate", "ndivselloci"))
#   
#   out_folder <- "data/slim_output"
#   
#   
#   launch_slim_job(model_params, sim_prefix = "clim_change", out_folder, n_reps = n_reps, dryrun = dry_run, array = array)
#   Sys.sleep(0.1)
# }

#system("tar czf slim_output.tar.gz data")
