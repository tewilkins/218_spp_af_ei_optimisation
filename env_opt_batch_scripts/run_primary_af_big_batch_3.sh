#!/bin/bash

# Define directories
WORKING_DIR="$HOME/git/mw_metabarcoding_model"
MODEL_DIR="$HOME/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/trial2_218spp_af_big_opt"
LOG_DIR="$HOME/uomShare/wergStaff/ChrisW/git-data/mw_metabarcoding_model/trial2_218spp_af_big_opt/logs"

# Ensure the logging folder exists before firing up the loop
mkdir -p "$LOG_DIR"
RUN_LOG="${LOG_DIR}/batch_run_$(date +%Y%m%d_%H%M%S).log"

# Define your explicit target model codes array here (Space-separated)
MOD_CODES=("af_l1w800" "af_l2w800" "af_l4w800" "af_l8w800" "af_l16w800" "af_l32w800" "af_l64w800")  

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
        Rscript batch_218_spp_opt_af_big.R  "$CODE"
        
        echo "Memory successfully flushed. Moving to next target string..."
        echo ""
    done

    echo "======================================================================"
    echo "BATCH OPERATION SUCCESSFUL COMPLETED: $(date)"
    echo "======================================================================"

} 2>&1 | tee -a "$RUN_LOG"
