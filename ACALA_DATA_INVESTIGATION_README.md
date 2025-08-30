# Acala Network Data Investigation and Machine Learning Pipeline

This project provides a comprehensive framework for investigating Acala network data structure and preparing it for machine learning analysis using the shrimp's Acala node container.

## 🎯 Overview

The Acala network is a DeFi-focused parachain in the Polkadot ecosystem. This pipeline allows you to:

1. **Investigate Data Structure**: Connect to the Acala node and explore its data structure
2. **Collect Sample Data**: Gather real network data for analysis
3. **Prepare ML Datasets**: Transform raw data into machine learning-ready features
4. **Train Predictive Models**: Build models to predict network behavior
5. **Generate Insights**: Create visualizations and reports

## 🚀 Quick Start

### Prerequisites

1. **Acala Node Running**: Ensure the Acala node container is running
   ```bash
   # Start the shrimp deployment
   ./scripts/deploy-polkadot-shrimp.sh
   
   # Or start just the Acala node
   docker-compose up acala
   ```

2. **Python Dependencies**: Install required packages
   ```bash
   pip3 install -r scripts/acala_requirements.txt
   ```

### Run Complete Pipeline

```bash
# Run the complete investigation and ML preparation
./scripts/run_acala_investigation.sh
```

This will:
- Check if the Acala node is accessible
- Install missing Python dependencies
- Run data structure investigation
- Prepare ML datasets
- Train predictive models
- Generate reports and visualizations
- Create an interactive Jupyter notebook

## 📁 Project Structure

```
scripts/
├── investigate_acala_data.py          # Data structure investigation
├── acala_data_preparation.py          # ML data preparation
├── run_acala_investigation.sh         # Complete pipeline runner
├── acala_requirements.txt             # Python dependencies
└── acala_analysis.ipynb               # Interactive analysis notebook

acala_data_investigation/              # Raw investigation data
├── acala_blocks_sample.csv           # Block data
├── acala_extrinsics_sample.csv       # Transaction data
├── acala_tokens_sample.csv           # Token data
└── investigation_summary.json        # Investigation report

acala_ml_data/                        # ML processed data
├── acala_features.csv                # ML feature matrix
├── acala_target_*.csv                # Target variables
├── acala_model_*.pkl                 # Trained models
├── acala_scaler.pkl                  # Feature scaler
├── acala_ml_results.json             # Model performance
├── acala_ml_report.md                # ML analysis report
└── feature_importance_*.png          # Feature importance plots
```

## 🔍 Data Investigation

### What We Investigate

1. **Block Structure**: Block headers, extrinsics, events, timestamps
2. **Transaction Data**: Extrinsics, fees, success rates, call modules
3. **Account Information**: Balances, nonces, locks, reserves
4. **Token Data**: ACA, AUSD, LDOT, LCDOT, KAR, KUSD
5. **Network Metrics**: Block times, transaction density, network activity

### Investigation Script

```python
# Run investigation manually
python3 scripts/investigate_acala_data.py
```

The investigation script:
- Connects to the Acala node at `http://localhost:9949`
- Collects sample data from recent blocks
- Analyzes data structure and relationships
- Saves results in multiple formats (CSV, JSON)

## 🤖 Machine Learning Preparation

### Feature Engineering

The ML preparation script creates the following features:

**Block-Level Features:**
- Block number, timestamp, size
- Extrinsics count, events count
- Era, session information

**Transaction-Level Features:**
- Total, successful, failed transactions
- Average, max, min transaction fees
- Transaction success rates

**Network-Level Features:**
- Active accounts, new accounts
- Total volume, average block time
- Network activity scores

**Token-Level Features:**
- ACA, AUSD, LDOT prices
- Total Value Locked (TVL)

### Target Variables

1. **Next Block Time**: Predict time to next block
2. **Next Block Size**: Predict size of next block
3. **Transaction Success Rate**: Predict transaction success probability
4. **Network Activity Score**: Predict network activity level

### ML Models

The pipeline trains Random Forest models for:
- Regression: Block time prediction
- Regression: Success rate prediction
- Regression: Activity score prediction

## 📊 Output Files

### Investigation Results

- **`acala_blocks_sample.csv`**: Block data with timestamps, sizes, extrinsics
- **`acala_extrinsics_sample.csv`**: Transaction data with fees, success status
- **`acala_tokens_sample.csv`**: Token information and metadata
- **`investigation_summary.json`**: Summary of data collection and structure

### ML Data

- **`acala_features.csv`**: Feature matrix for ML training
- **`acala_target_*.csv`**: Target variables for each prediction task
- **`acala_model_*.pkl`**: Trained scikit-learn models
- **`acala_scaler.pkl`**: Feature scaling parameters

### Reports and Visualizations

- **`acala_ml_report.md`**: Comprehensive ML analysis report
- **`acala_ml_results.json`**: Model performance metrics
- **`feature_importance_*.png`**: Feature importance visualizations

## 🔧 Configuration

### Acala Node Configuration

The investigation connects to the Acala node at:
- **URL**: `http://localhost:9949`
- **Container**: `acala-node` (from shrimp deployment)
- **Port**: `9949` (mapped from container port `9944`)

### Data Collection Settings

```python
# In investigate_acala_data.py
num_blocks = 20  # Number of blocks to investigate
rate_limit_delay = 0.1  # Seconds between requests
```

### ML Settings

```python
# In acala_data_preparation.py
test_size = 0.2  # Test set size
random_state = 42  # Random seed
n_estimators = 100  # Random Forest trees
```

## 📈 Usage Examples

### Interactive Analysis

```bash
# Start Jupyter notebook
jupyter notebook scripts/acala_analysis.ipynb
```

### Load Trained Models

```python
import pickle
import pandas as pd

# Load model
with open('acala_ml_data/acala_model_next_block_time.pkl', 'rb') as f:
    model = pickle.load(f)

# Load scaler
with open('acala_ml_data/acala_scaler.pkl', 'rb') as f:
    scaler = pickle.load(f)

# Make predictions
features = pd.read_csv('acala_ml_data/acala_features.csv')
scaled_features = scaler.transform(features)
predictions = model.predict(scaled_features)
```

### Custom Data Collection

```python
from scripts.investigate_acala_data import AcalaDataInvestigator

async with AcalaDataInvestigator("http://localhost:9949") as investigator:
    # Collect more blocks
    await investigator.collect_sample_data(num_blocks=100)
    
    # Investigate specific block
    block_data = await investigator.investigate_block_structure(12345)
    
    # Investigate specific account
    account_data = await investigator.investigate_account_structure("0x...")
```

## 🛠 Troubleshooting

### Common Issues

1. **Acala Node Not Accessible**
   ```bash
   # Check if container is running
   docker ps | grep acala
   
   # Start the node
   docker-compose up acala
   ```

2. **Python Dependencies Missing**
   ```bash
   # Install requirements
   pip3 install -r scripts/acala_requirements.txt
   ```

3. **Insufficient Data**
   ```bash
   # Wait for node to sync or collect more data
   # Modify num_blocks in investigate_acala_data.py
   ```

4. **Memory Issues**
   ```bash
   # Reduce number of blocks collected
   # Use smaller batch sizes in data preparation
   ```

### Logs

- **Investigation logs**: `acala_investigation.log`
- **Preparation logs**: `acala_data_preparation.log`
- **Pipeline logs**: Check console output

## 🔮 Future Enhancements

### Planned Features

1. **Real-time Data Collection**: WebSocket connections for live data
2. **Advanced ML Models**: Deep learning, time series models
3. **External Data Integration**: Price feeds, TVL data, social metrics
4. **Automated Monitoring**: Continuous model retraining and evaluation
5. **API Integration**: REST API for model predictions
6. **Dashboard**: Real-time visualization dashboard

### Extensions

- **Multi-network Analysis**: Compare Acala with other parachains
- **Cross-chain Analysis**: Analyze interactions between networks
- **Anomaly Detection**: Identify unusual network behavior
- **Predictive Analytics**: Forecast network growth and adoption

## 📚 References

- [Acala Network Documentation](https://acala.network/)
- [Polkadot Substrate Documentation](https://substrate.dev/)
- [Scikit-learn Documentation](https://scikit-learn.org/)
- [Pandas Documentation](https://pandas.pydata.org/)

## 🤝 Contributing

To contribute to this project:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is part of the DeFiMon analytics platform and follows the same licensing terms.

---

**Note**: This pipeline is designed for educational and research purposes. Always validate predictions and results before making any financial decisions based on the analysis.
