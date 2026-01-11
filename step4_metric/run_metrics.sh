#!/bin/bash

# =============================================================================
# Metrics Evaluation Pipeline (ICLR 2026)
# =============================================================================
#
# This script evaluates travel plans using LLM-as-a-Judge methodology.
# It compares MAD-based plans with Rule-based plans.
#
# API Key:
#   Automatically loaded from ../iclr2026/.env file
#
# Usage:
#   ./run_metrics.sh [OPTIONS]
#
# Options:
#   --mad_plans <path>        Path to MAD plans directory
#   --rule_plans <path>       Path to Rule-based plans directory
#   --output_dir <path>       Output directory (default: outputs/metrics)
#   --model <model>           Judge model (default: gpt-4o)
#   --temperature <float>     Temperature (default: 0.0)
#   --help                    Show this help message
#
# Examples:
#   # Run with default paths
#   ./run_metrics.sh
#
#   # Use custom paths
#   ./run_metrics.sh --mad_plans ../step2_mad/outputs/results \
#                    --rule_plans ../step2_rule_base/outputs/results
#
#   # Use budget model
#   ./run_metrics.sh --model gpt-4o-mini
#
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# =============================================================================
# Configuration
# =============================================================================

# Default parameters
MAD_PLANS="${MAD_PLANS:-../step2_mad/outputs/mad_results}"
RULE_PLANS="${RULE_PLANS:-../step2_rule_base/outputs/rule_base_results}"
OUTPUT_DIR="outputs/metrics"
MODEL="gpt-4.1-mini"
TEMPERATURE=0.0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --mad_plans)
            MAD_PLANS="$2"
            shift 2
            ;;
        --rule_plans)
            RULE_PLANS="$2"
            shift 2
            ;;
        --output_dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --temperature)
            TEMPERATURE="$2"
            shift 2
            ;;
        --help)
            sed -n '3,35p' "$0" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Run './run_metrics.sh --help' for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# Environment Check
# =============================================================================

echo "========================================================================"
echo "  Metrics Evaluation Pipeline"
echo "========================================================================"
echo ""
echo "Configuration:"
echo "  - MAD plans: $MAD_PLANS"
echo "  - Rule plans: $RULE_PLANS"
echo "  - Output dir: $OUTPUT_DIR"
echo "  - Judge model: $MODEL"
echo "  - Temperature: $TEMPERATURE"
echo ""

# Load .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/../.env"

if [[ -f "$ENV_FILE" ]]; then
    echo "Loading environment variables from $ENV_FILE"
    set +u  # Temporarily disable undefined variable check
    # Export variables from .env (skip comments and empty lines)
    export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
    set -u  # Re-enable undefined variable check
    echo "✓ Environment variables loaded"
    echo ""
else
    echo "Warning: .env file not found at $ENV_FILE"
    echo ""
fi

# Check API key
if [[ -z "${OPENAI_API_KEY:-}" ]]; then
    echo "Error: OPENAI_API_KEY environment variable is not set"
    echo ""
    echo "Please either:"
    echo "  1. Add OPENAI_API_KEY to $ENV_FILE"
    echo "  2. Set it manually: export OPENAI_API_KEY='sk-...'"
    exit 1
fi

echo "✓ OPENAI_API_KEY found"
echo ""

# =============================================================================
# Input Validation
# =============================================================================

echo "========================================================================"
echo "  Validating Inputs"
echo "========================================================================"
echo ""

# Check if MAD plans exist (optional, may not be ready yet)
if [[ -d "$MAD_PLANS" ]]; then
    MAD_COUNT=$(find "$MAD_PLANS" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    echo "✓ MAD plans found: $MAD_COUNT files"
else
    echo "⚠ MAD plans directory not found: $MAD_PLANS"
    echo "  (This is OK if MAD step hasn't been run yet)"
    MAD_COUNT=0
fi

# Check if Rule-based plans exist (optional)
if [[ -d "$RULE_PLANS" ]]; then
    RULE_COUNT=$(find "$RULE_PLANS" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
    echo "✓ Rule-based plans found: $RULE_COUNT files"
else
    echo "⚠ Rule-based plans directory not found: $RULE_PLANS"
    echo "  (This is OK if Rule-based step hasn't been run yet)"
    RULE_COUNT=0
fi

echo ""

# Exit if no plans available
if [[ $MAD_COUNT -eq 0 && $RULE_COUNT -eq 0 ]]; then
    echo "Error: No travel plans found to evaluate"
    echo ""
    echo "Please run either:"
    echo "  - MAD pipeline: cd ../step2_mad && ./run_mad.sh"
    echo "  - Rule-based: cd ../step2_rule_base && ./run_rule_base.sh"
    exit 1
fi

# =============================================================================
# Run Metrics Evaluation
# =============================================================================

echo "========================================================================"
echo "  Running LLM-as-a-Judge Evaluation"
echo "========================================================================"
echo ""

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Run main.py
python3 main.py \
    --mad_plans "$MAD_PLANS" \
    --rule_plans "$RULE_PLANS" \
    --output_dir "$OUTPUT_DIR" \
    --model "$MODEL" \
    --temperature "$TEMPERATURE"

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✓ Metrics evaluation completed successfully"
    echo ""
else
    echo ""
    echo "✗ Metrics evaluation failed"
    exit 1
fi

# =============================================================================
# Final Summary
# =============================================================================

echo "========================================================================"
echo "  Evaluation Completed Successfully!"
echo "========================================================================"
echo ""
echo "Outputs:"
echo "  - Results directory: $OUTPUT_DIR"
echo ""

# Check for output files
if [[ -f "$OUTPUT_DIR/summary.json" ]]; then
    echo "Summary file:"
    echo "  - $OUTPUT_DIR/summary.json"
    echo ""
    echo "Summary preview:"
    head -20 "$OUTPUT_DIR/summary.json" | sed 's/^/  /'
    echo "  ..."
    echo ""
fi

# Count results
RESULT_COUNT=$(find "$OUTPUT_DIR" -name "*.json" 2>/dev/null | wc -l | tr -d ' ')
echo "Total result files: $RESULT_COUNT"
echo ""

echo "Next steps:"
echo "  - Analyze results: python analyze_results.py --input $OUTPUT_DIR"
echo "  - Generate plots: python plot_metrics.py --input $OUTPUT_DIR"
echo ""
echo "Done! 🎉"
