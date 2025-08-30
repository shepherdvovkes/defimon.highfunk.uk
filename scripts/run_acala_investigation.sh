#!/bin/bash

# Acala Network Data Investigation and ML Preparation Script
# This script runs the complete pipeline to investigate Acala network data structure
# and prepare it for machine learning analysis

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ACALA_NODE_URL="http://localhost:9949"
INVESTIGATION_SCRIPT="investigate_acala_data.py"
PREPARATION_SCRIPT="acala_data_preparation.py"
REQUIREMENTS_FILE="acala_requirements.txt"

echo -e "${BLUE}=== Acala Network Data Investigation and ML Preparation ===${NC}"
echo "Script directory: $SCRIPT_DIR"
echo "Project root: $PROJECT_ROOT"
echo "Acala node URL: $ACALA_NODE_URL"
echo ""

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Acala node is running
check_acala_node() {
    print_status "Checking if Acala node is running..."
    
    if curl -s "$ACALA_NODE_URL" > /dev/null 2>&1; then
        print_status "Acala node is accessible at $ACALA_NODE_URL"
        return 0
    else
        print_error "Acala node is not accessible at $ACALA_NODE_URL"
        print_warning "Make sure the Acala node container is running:"
        echo "  docker-compose up acala"
        echo "  or"
        echo "  ./scripts/deploy-polkadot-shrimp.sh"
        return 1
    fi
}

# Function to check Python dependencies
check_python_dependencies() {
    print_status "Checking Python dependencies..."
    
    if ! command -v python3 &> /dev/null; then
        print_error "Python 3 is not installed"
        return 1
    fi
    
    if ! python3 -c "import pandas, numpy, aiohttp, sklearn" 2>/dev/null; then
        print_warning "Some required Python packages are missing"
        print_status "Installing dependencies from $REQUIREMENTS_FILE..."
        
        if [ -f "$SCRIPT_DIR/$REQUIREMENTS_FILE" ]; then
            pip3 install -r "$SCRIPT_DIR/$REQUIREMENTS_FILE"
        else
            print_error "Requirements file not found: $SCRIPT_DIR/$REQUIREMENTS_FILE"
            return 1
        fi
    else
        print_status "All required Python packages are available"
    fi
}

# Function to run data investigation
run_investigation() {
    print_status "Starting Acala data structure investigation..."
    
    cd "$SCRIPT_DIR"
    
    if [ ! -f "$INVESTIGATION_SCRIPT" ]; then
        print_error "Investigation script not found: $INVESTIGATION_SCRIPT"
        return 1
    fi
    
    print_status "Running investigation script..."
    python3 "$INVESTIGATION_SCRIPT"
    
    if [ $? -eq 0 ]; then
        print_status "Investigation completed successfully"
        return 0
    else
        print_error "Investigation failed"
        return 1
    fi
}

# Function to run data preparation
run_preparation() {
    print_status "Starting Acala data preparation for ML..."
    
    cd "$SCRIPT_DIR"
    
    if [ ! -f "$PREPARATION_SCRIPT" ]; then
        print_error "Preparation script not found: $PREPARATION_SCRIPT"
        return 1
    fi
    
    print_status "Running preparation script..."
    python3 "$PREPARATION_SCRIPT"
    
    if [ $? -eq 0 ]; then
        print_status "Data preparation completed successfully"
        return 0
    else
        print_error "Data preparation failed"
        return 1
    fi
}

# Function to display results
display_results() {
    print_status "Displaying investigation results..."
    
    cd "$SCRIPT_DIR"
    
    # Check for investigation results
    if [ -d "acala_data_investigation" ]; then
        echo ""
        echo -e "${BLUE}=== Investigation Results ===${NC}"
        echo "Data directory: acala_data_investigation/"
        
        if [ -f "acala_data_investigation/investigation_summary.json" ]; then
            echo "Summary report: acala_data_investigation/investigation_summary.json"
        fi
        
        if [ -f "acala_data_investigation/acala_blocks_sample.csv" ]; then
            BLOCKS_COUNT=$(wc -l < "acala_data_investigation/acala_blocks_sample.csv")
            echo "Blocks collected: $((BLOCKS_COUNT - 1))"  # Subtract header
        fi
        
        if [ -f "acala_data_investigation/acala_extrinsics_sample.csv" ]; then
            EXTRINSICS_COUNT=$(wc -l < "acala_data_investigation/acala_extrinsics_sample.csv")
            echo "Extrinsics collected: $((EXTRINSICS_COUNT - 1))"  # Subtract header
        fi
        
        if [ -f "acala_data_investigation/acala_tokens_sample.csv" ]; then
            TOKENS_COUNT=$(wc -l < "acala_data_investigation/acala_tokens_sample.csv")
            echo "Tokens collected: $((TOKENS_COUNT - 1))"  # Subtract header
        fi
    fi
    
    # Check for ML results
    if [ -d "acala_ml_data" ]; then
        echo ""
        echo -e "${BLUE}=== ML Preparation Results ===${NC}"
        echo "ML data directory: acala_ml_data/"
        
        if [ -f "acala_ml_data/acala_ml_report.md" ]; then
            echo "ML report: acala_ml_data/acala_ml_report.md"
        fi
        
        if [ -f "acala_ml_data/acala_features.csv" ]; then
            FEATURES_COUNT=$(wc -l < "acala_ml_data/acala_features.csv")
            echo "ML features: $((FEATURES_COUNT - 1)) samples"  # Subtract header
        fi
        
        # List model files
        MODEL_FILES=$(ls acala_ml_data/acala_model_*.pkl 2>/dev/null || true)
        if [ -n "$MODEL_FILES" ]; then
            echo "Trained models:"
            for model in $MODEL_FILES; do
                echo "  - $(basename "$model")"
            done
        fi
        
        # List visualization files
        PLOT_FILES=$(ls acala_ml_data/feature_importance_*.png 2>/dev/null || true)
        if [ -n "$PLOT_FILES" ]; then
            echo "Visualizations:"
            for plot in $PLOT_FILES; do
                echo "  - $(basename "$plot")"
            done
        fi
    fi
}

# Function to create analysis notebook
create_analysis_notebook() {
    print_status "Creating Jupyter analysis notebook..."
    
    cd "$SCRIPT_DIR"
    
    cat > "acala_analysis.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Acala Network Data Analysis\n",
    "\n",
    "This notebook provides interactive analysis of the Acala network data collected by the investigation scripts."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "import json\n",
    "from pathlib import Path\n",
    "\n",
    "# Set up plotting style\n",
    "plt.style.use('seaborn-v0_8')\n",
    "sns.set_palette(\"husl\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Load Investigation Data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load blocks data\n",
    "blocks_df = pd.read_csv('acala_data_investigation/acala_blocks_sample.csv')\n",
    "print(f\"Loaded {len(blocks_df)} blocks\")\n",
    "blocks_df.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load extrinsics data\n",
    "extrinsics_df = pd.read_csv('acala_data_investigation/acala_extrinsics_sample.csv')\n",
    "print(f\"Loaded {len(extrinsics_df)} extrinsics\")\n",
    "extrinsics_df.head()"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Load ML Data"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load ML features\n",
    "features_df = pd.read_csv('acala_ml_data/acala_features.csv')\n",
    "print(f\"Loaded {len(features_df)} ML feature samples\")\n",
    "features_df.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load ML results\n",
    "with open('acala_ml_data/acala_ml_results.json', 'r') as f:\n",
    "    ml_results = json.load(f)\n",
    "\n",
    "print(\"ML Model Results:\")\n",
    "for model_name, result in ml_results.items():\n",
    "    print(f\"{model_name}: RMSE = {result['rmse']:.4f}\")"
   ]
  },
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "## Data Visualization"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Block size distribution\n",
    "plt.figure(figsize=(12, 6))\n",
    "plt.subplot(1, 2, 1)\n",
    "plt.hist(blocks_df['block_size'], bins=20, alpha=0.7)\n",
    "plt.title('Block Size Distribution')\n",
    "plt.xlabel('Block Size')\n",
    "plt.ylabel('Frequency')\n",
    "\n",
    "plt.subplot(1, 2, 2)\n",
    "plt.hist(blocks_df['extrinsics_count'], bins=20, alpha=0.7)\n",
    "plt.title('Extrinsics Count Distribution')\n",
    "plt.xlabel('Extrinsics Count')\n",
    "plt.ylabel('Frequency')\n",
    "\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Feature importance visualization\n",
    "for model_name, result in ml_results.items():\n",
    "    importance = result['feature_importance']\n",
    "    top_features = sorted(importance.items(), key=lambda x: x[1], reverse=True)[:10]\n",
    "    \n",
    "    features, scores = zip(*top_features)\n",
    "    \n",
    "    plt.figure(figsize=(10, 6))\n",
    "    plt.barh(range(len(features)), scores)\n",
    "    plt.yticks(range(len(features)), features)\n",
    "    plt.xlabel('Feature Importance')\n",
    "    plt.title(f'Top 10 Feature Importance - {model_name.replace(\"_\", \" \").title()}')\n",
    "    plt.gca().invert_yaxis()\n",
    "    plt.tight_layout()\n",
    "    plt.show()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.8.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF

    print_status "Created analysis notebook: acala_analysis.ipynb"
}

# Main execution
main() {
    echo -e "${BLUE}Starting Acala Network Data Investigation Pipeline${NC}"
    echo ""
    
    # Check prerequisites
    if ! check_acala_node; then
        print_error "Prerequisites check failed. Please ensure Acala node is running."
        exit 1
    fi
    
    if ! check_python_dependencies; then
        print_error "Python dependencies check failed."
        exit 1
    fi
    
    # Run investigation
    if ! run_investigation; then
        print_error "Data investigation failed."
        exit 1
    fi
    
    # Run preparation
    if ! run_preparation; then
        print_error "Data preparation failed."
        exit 1
    fi
    
    # Display results
    display_results
    
    # Create analysis notebook
    create_analysis_notebook
    
    echo ""
    echo -e "${GREEN}=== Acala Network Data Investigation Completed Successfully ===${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Review the investigation results in acala_data_investigation/"
    echo "2. Examine the ML models and results in acala_ml_data/"
    echo "3. Open acala_analysis.ipynb for interactive analysis"
    echo "4. Use the trained models for predictions on new Acala data"
    echo ""
    echo "Files created:"
    echo "- acala_data_investigation/ - Raw investigation data"
    echo "- acala_ml_data/ - Processed ML data and models"
    echo "- acala_analysis.ipynb - Interactive analysis notebook"
    echo "- acala_investigation.log - Investigation logs"
    echo "- acala_data_preparation.log - Preparation logs"
}

# Run main function
main "$@"
