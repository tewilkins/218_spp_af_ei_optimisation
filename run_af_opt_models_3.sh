#!/bin/bas
models=("tf" "af_l1w1000" "af_l2w1000" "af_l4w1000" "af_l6w1000" "af_l8w1000" "af_l10w1000" "af_l1w1200" "af_l2w1200" "af_l4w1200")

# Loop through each model code and run it in a fresh R session
for model in "${models[@]}"
do
    echo "========================================="
    echo "Starting batch job for: $model"
    echo "========================================="

    # Run the R script and pass the current model name as an argument
    Rscript batch_218_spp_opt_af.R "$model"

    echo "Finished: $model. RAM cleared by Linux OS."
    echo ""
done

echo "All Stan models have successfully finished processing!"