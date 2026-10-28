#!/bin/bash

# Define directories
WORKING_DIR="$HOME/git/mw_metabarcoding_model"
MODEL_DIR="$HOME/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/af_opt_ei_l2sw40_196_spp_ifqctl_fi_qf_qi_fiq"
LOG_DIR="$HOME/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/af_opt_ei_l2sw40_196_spp_ifqctl_fi_qf_qi_fiq/logs"

# Ensure the logging folder exists before firing up the loop
mkdir -p "$LOG_DIR"
RUN_LOG="${LOG_DIR}/batch_run_$(date +%Y%m%d_%H%M%S).log"

# Define your explicit target model codes array here (Space-separated)
MOD_CODES=("af_l3.75w625" "af_l4w633" "af_l4w1600" "af_l8w1600" "af_l4w625" "af_l1w1600" "af_l2w1600" "af_l1w400" "af_l2w400" "af_l1w1000" "af_l1w1200" "af_l10w400" "af_l10w800" "af_l10w1200")

# ==============================================================================
# BASH CORE LOOP WITH 'TEE' LOGGING CAPTURE
# ==============================================================================
# The '{ ... } 2>&1 | tee -a "$RUN_LOG"' wrapper forces Bash to stream BOTH 
# standard prints (stdout) and fatal errors (stderr) straight into your log file!
{
    echo "======================================================================"
    echo "STARTING BATCH MOMENT-MATCHING OPERATION: $(date)"
    echo "Log file destination: $RUN_LOG"
    echo "======================================================================"
    echo ""
    
    # Move to your working git repository folder so R can see 'stancode/...' relatively
    cd "$WORKING_DIR" || exit 1

    for CODE in "${MOD_CODES[@]}"; do
        echo "----------------------------------------------------------------------"
        echo "LAUNCHING FRESH ISOLATED R ENVIRONMENT FOR CODE: $CODE"
        echo "Time: $(date)"
        echo "----------------------------------------------------------------------"
        
        # Run your isolated Rscript command line utility execution block
        Rscript run_1_model_bash_script.R  "$CODE"
        
        echo "Memory successfully flushed. Moving to next target string..."
        echo ""
    done

    echo "======================================================================"
    echo "BATCH OPERATION SUCCESSFUL COMPLETED: $(date)"
    echo "======================================================================"

} 2>&1 | tee -a "$RUN_LOG"