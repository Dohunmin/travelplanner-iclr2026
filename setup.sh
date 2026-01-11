#!/bin/bash

# =============================================================================
# ICLR 2026 Paper Reproduction - Setup Script
# =============================================================================
#
# This script sets up the complete environment for reproducing the paper.
# It creates conda environments and validates the setup.
#
# Usage:
#   ./setup.sh [OPTIONS]
#
# Options:
#   --skip-conda          Skip conda environment creation
#   --help                Show this help message
#
# =============================================================================

set -e  # Exit on error
set -u  # Exit on undefined variable

# =============================================================================
# Configuration
# =============================================================================

SKIP_CONDA=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-conda)
            SKIP_CONDA=true
            shift
            ;;
        --help)
            sed -n '3,17p' "$0" | sed 's/^# //' | sed 's/^#//'
            exit 0
            ;;
        *)
            echo "Error: Unknown option $1"
            echo "Run './setup.sh --help' for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# Environment Setup
# =============================================================================

echo "========================================================================"
echo "  ICLR 2026 Paper Reproduction - Setup"
echo "========================================================================"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# =============================================================================
# Step 1: Check Prerequisites
# =============================================================================

echo "Step 1: Checking prerequisites..."
echo ""

# Check conda
if ! command -v conda &> /dev/null; then
    echo "✗ Error: conda not found"
    echo ""
    echo "Please install Anaconda or Miniconda first:"
    echo "  https://docs.conda.io/en/latest/miniconda.html"
    exit 1
fi
echo "✓ conda found: $(conda --version)"

# Check python
if ! command -v python3 &> /dev/null; then
    echo "✗ Error: python3 not found"
    exit 1
fi
echo "✓ python3 found: $(python3 --version)"

echo ""

# =============================================================================
# Step 2: Create .env File
# =============================================================================

echo "Step 2: Setting up environment variables..."
echo ""

ENV_FILE="$SCRIPT_DIR/.env"
ENV_EXAMPLE="$SCRIPT_DIR/.env.example"

if [[ -f "$ENV_FILE" ]]; then
    echo "✓ .env file already exists"
    echo ""
else
    if [[ -f "$ENV_EXAMPLE" ]]; then
        cp "$ENV_EXAMPLE" "$ENV_FILE"
        echo "✓ Created .env from .env.example"
        echo ""
        echo "⚠ IMPORTANT: Please edit .env and add your API keys:"
        echo "  - OPENAI_API_KEY=sk-your-key-here"
        echo ""
        echo "Then run setup.sh again."
        exit 0
    else
        echo "✗ Error: .env.example not found"
        exit 1
    fi
fi

# Validate API key
source "$ENV_FILE"
if [[ -z "${OPENAI_API_KEY:-}" ]] || [[ "$OPENAI_API_KEY" == "sk-" ]]; then
    echo "✗ Error: OPENAI_API_KEY not set in .env"
    echo ""
    echo "Please edit .env and add your OpenAI API key:"
    echo "  OPENAI_API_KEY=sk-your-actual-key-here"
    exit 1
fi
echo "✓ OPENAI_API_KEY is set"
echo ""

# =============================================================================
# Step 3: Create Conda Environments
# =============================================================================

if [[ "$SKIP_CONDA" == false ]]; then
    echo "Step 3: Creating conda environments..."
    echo ""

    # Step 1: Multi-Persona Augmentation
    if [[ -f "$SCRIPT_DIR/step1_persona_aug/mp_aug.yml" ]]; then
        echo "Creating mp_aug environment..."
        if conda env list | grep -q "^mp_aug "; then
            echo "  Environment 'mp_aug' already exists, skipping..."
        else
            conda env create -f "$SCRIPT_DIR/step1_persona_aug/mp_aug.yml"
            echo "  ✓ mp_aug environment created"
        fi
        echo ""
    else
        echo "⚠ Warning: step1_persona_aug/mp_aug.yml not found, skipping..."
        echo ""
    fi

    # Step 2: MAD (if available)
    if [[ -f "$SCRIPT_DIR/step2_mad/mad.yml" ]]; then
        echo "Creating mad environment..."
        if conda env list | grep -q "^mad "; then
            echo "  Environment 'mad' already exists, skipping..."
        else
            conda env create -f "$SCRIPT_DIR/step2_mad/mad.yml"
            echo "  ✓ mad environment created"
        fi
        echo ""
    else
        echo "⚠ step2_mad/mad.yml not found (this is OK if MAD is not ready yet)"
        echo ""
    fi

    echo "✓ Conda environments setup complete"
    echo ""
else
    echo "Step 3: Skipping conda environment creation (--skip-conda)"
    echo ""
fi

# =============================================================================
# Step 4: Verify Directory Structure
# =============================================================================

echo "Step 4: Verifying directory structure..."
echo ""

# Check each step directory
STEPS=("step1_persona_aug" "step2_mad" "step2_rule_base" "step3_solver" "step4_metric")
for step in "${STEPS[@]}"; do
    if [[ -d "$SCRIPT_DIR/$step" ]]; then
        echo "✓ $step/"

        # Check for shell script
        SHELL_SCRIPTS=("$SCRIPT_DIR/$step"/*.sh)
        if [[ -f "${SHELL_SCRIPTS[0]}" ]]; then
            # Make shell scripts executable
            chmod +x "$SCRIPT_DIR/$step"/*.sh 2>/dev/null || true
        fi
    else
        echo "⚠ $step/ (not found)"
    fi
done

echo ""

# =============================================================================
# Final Summary
# =============================================================================

echo "========================================================================"
echo "  Setup Complete!"
echo "========================================================================"
echo ""
echo "Available pipelines:"
echo ""

# Step 1
if [[ -f "$SCRIPT_DIR/step1_persona_aug/run_aug.sh" ]]; then
    echo "  1. Multi-Persona Augmentation:"
    echo "     cd step1_persona_aug && ./run_aug.sh"
    echo ""
fi

# Step 2a
if [[ -f "$SCRIPT_DIR/step2_mad/run_mad.sh" ]]; then
    echo "  2a. Multi-Agent Debate (MAD):"
    echo "      cd step2_mad && ./run_mad.sh"
    echo ""
else
    echo "  2a. Multi-Agent Debate (MAD): [Not ready yet]"
    echo ""
fi

# Step 2b
if [[ -f "$SCRIPT_DIR/step2_rule_base/run_rule_base.sh" ]]; then
    echo "  2b. Rule-based Travel Planning:"
    echo "      cd step2_rule_base && ./run_rule_base.sh"
    echo ""
else
    echo "  2b. Rule-based Travel Planning: [Not ready yet]"
    echo ""
fi

# Step 3
if [[ -f "$SCRIPT_DIR/step3_solver/run_solver.sh" ]]; then
    echo "  3. Z3 Solver:"
    echo "     cd step3_solver && ./run_solver.sh"
    echo ""
else
    echo "  3. Z3 Solver: [Not ready yet]"
    echo ""
fi

# Step 4
if [[ -f "$SCRIPT_DIR/step4_metric/run_metrics.sh" ]]; then
    echo "  4. Metrics Evaluation:"
    echo "     cd step4_metric && ./run_metrics.sh"
    echo ""
fi

echo "Environment files:"
echo "  - .env: Contains API keys (created)"

if [[ "$SKIP_CONDA" == false ]]; then
    echo "  - mp_aug: Conda environment for Step 1 (created)"
    if [[ -f "$SCRIPT_DIR/step2_mad/mad.yml" ]]; then
        echo "  - mad: Conda environment for Step 2a (created)"
    fi
fi

echo ""
echo "Next steps:"
echo "  1. Activate the environment: conda activate mp_aug"
echo "  2. Run Step 1: cd step1_persona_aug && ./run_aug.sh --max_records 10"
echo ""
echo "Done! 🎉"
