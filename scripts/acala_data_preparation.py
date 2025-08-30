#!/usr/bin/env python3
"""
Acala Network Data Preparation Script for Machine Learning
Prepares and processes Acala network data for ML analysis
"""

import asyncio
import json
import logging
import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
import aiohttp
from dataclasses import dataclass, asdict
from pathlib import Path
import pickle
import gzip
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestRegressor, RandomForestClassifier
from sklearn.metrics import mean_squared_error, accuracy_score, classification_report
import matplotlib.pyplot as plt
import seaborn as sns

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('acala_data_preparation.log'),
        logging.StreamHandler()
    ]
)

@dataclass
class AcalaMLFeatures:
    """Machine learning features for Acala network analysis"""
    # Block-level features
    block_number: int
    block_timestamp: int
    extrinsics_count: int
    events_count: int
    block_size: int
    era: int
    session: int
    
    # Transaction-level features
    total_transactions: int
    successful_transactions: int
    failed_transactions: int
    avg_transaction_fee: float
    max_transaction_fee: float
    min_transaction_fee: float
    
    # Network-level features
    active_accounts: int
    new_accounts: int
    total_volume: float
    avg_block_time: float
    
    # Token-level features
    aca_price: Optional[float]
    ausd_price: Optional[float]
    ldot_price: Optional[float]
    total_tvl: Optional[float]
    
    # Target variables
    next_block_time: Optional[float] = None
    next_block_size: Optional[int] = None
    transaction_success_rate: Optional[float] = None
    network_activity_score: Optional[float] = None

class AcalaDataPreparator:
    """Data preparation for Acala network ML analysis"""
    
    def __init__(self, data_dir: str = "acala_data_investigation"):
        self.data_dir = Path(data_dir)
        self.output_dir = Path("acala_ml_data")
        self.output_dir.mkdir(exist_ok=True)
        
        # Data storage
        self.blocks_df: Optional[pd.DataFrame] = None
        self.extrinsics_df: Optional[pd.DataFrame] = None
        self.tokens_df: Optional[pd.DataFrame] = None
        self.ml_features: List[AcalaMLFeatures] = []
        
        # ML preprocessing
        self.scaler = StandardScaler()
        self.label_encoders: Dict[str, LabelEncoder] = {}
        
    def load_investigation_data(self) -> bool:
        """Load data from investigation files"""
        logging.info("Loading investigation data...")
        
        try:
            # Load blocks data
            blocks_file = self.data_dir / "acala_blocks_sample.csv"
            if blocks_file.exists():
                self.blocks_df = pd.read_csv(blocks_file)
                logging.info(f"Loaded {len(self.blocks_df)} blocks")
            else:
                logging.warning("Blocks data file not found")
                return False
            
            # Load extrinsics data
            extrinsics_file = self.data_dir / "acala_extrinsics_sample.csv"
            if extrinsics_file.exists():
                self.extrinsics_df = pd.read_csv(extrinsics_file)
                logging.info(f"Loaded {len(self.extrinsics_df)} extrinsics")
            else:
                logging.warning("Extrinsics data file not found")
                return False
            
            # Load tokens data
            tokens_file = self.data_dir / "acala_tokens_sample.csv"
            if tokens_file.exists():
                self.tokens_df = pd.read_csv(tokens_file)
                logging.info(f"Loaded {len(self.tokens_df)} tokens")
            else:
                logging.warning("Tokens data file not found")
            
            return True
            
        except Exception as e:
            logging.error(f"Error loading data: {e}")
            return False
    
    def clean_and_preprocess_data(self) -> None:
        """Clean and preprocess the raw data"""
        logging.info("Cleaning and preprocessing data...")
        
        if self.blocks_df is not None:
            # Clean blocks data
            self.blocks_df = self.blocks_df.dropna(subset=['block_number', 'block_hash'])
            self.blocks_df['timestamp'] = pd.to_datetime(self.blocks_df['timestamp'], unit='s', errors='coerce')
            self.blocks_df['block_size'] = pd.to_numeric(self.blocks_df['block_size'], errors='coerce').fillna(0)
            self.blocks_df['extrinsics_count'] = pd.to_numeric(self.blocks_df['extrinsics_count'], errors='coerce').fillna(0)
            self.blocks_df['events_count'] = pd.to_numeric(self.blocks_df['events_count'], errors='coerce').fillna(0)
            
            # Sort by block number
            self.blocks_df = self.blocks_df.sort_values('block_number').reset_index(drop=True)
            
            logging.info(f"Cleaned blocks data: {len(self.blocks_df)} records")
        
        if self.extrinsics_df is not None:
            # Clean extrinsics data
            self.extrinsics_df = self.extrinsics_df.dropna(subset=['block_number', 'extrinsic_index'])
            self.extrinsics_df['fee'] = pd.to_numeric(self.extrinsics_df['fee'], errors='coerce').fillna(0)
            self.extrinsics_df['nonce'] = pd.to_numeric(self.extrinsics_df['nonce'], errors='coerce').fillna(0)
            
            # Create success indicator
            self.extrinsics_df['success'] = self.extrinsics_df['success'].astype(bool)
            
            logging.info(f"Cleaned extrinsics data: {len(self.extrinsics_df)} records")
    
    def engineer_features(self) -> None:
        """Engineer features for machine learning"""
        logging.info("Engineering ML features...")
        
        if self.blocks_df is None or self.extrinsics_df is None:
            logging.error("Required data not loaded")
            return
        
        # Group extrinsics by block
        block_extrinsics = self.extrinsics_df.groupby('block_number').agg({
            'extrinsic_index': 'count',
            'fee': ['sum', 'mean', 'max', 'min'],
            'success': ['sum', 'mean'],
            'nonce': 'mean'
        }).reset_index()
        
        # Flatten column names
        block_extrinsics.columns = [
            'block_number', 'total_transactions', 'total_fee', 'avg_fee', 
            'max_fee', 'min_fee', 'successful_transactions', 'success_rate', 'avg_nonce'
        ]
        
        # Merge with blocks data
        merged_data = self.blocks_df.merge(block_extrinsics, on='block_number', how='left')
        
        # Calculate additional features
        merged_data['failed_transactions'] = merged_data['total_transactions'] - merged_data['successful_transactions']
        merged_data['block_time'] = merged_data['timestamp'].diff().dt.total_seconds()
        merged_data['avg_block_time'] = merged_data['block_time'].rolling(window=10, min_periods=1).mean()
        
        # Calculate network activity features
        merged_data['transaction_density'] = merged_data['total_transactions'] / merged_data['block_size']
        merged_data['event_density'] = merged_data['events_count'] / merged_data['block_size']
        
        # Create ML features
        for idx, row in merged_data.iterrows():
            if idx == 0:  # Skip first row (no previous data)
                continue
                
            # Get previous block data for target variables
            prev_row = merged_data.iloc[idx - 1]
            
            features = AcalaMLFeatures(
                # Block-level features
                block_number=int(row['block_number']),
                block_timestamp=int(row['timestamp'].timestamp()) if pd.notna(row['timestamp']) else 0,
                extrinsics_count=int(row['extrinsics_count']),
                events_count=int(row['events_count']),
                block_size=int(row['block_size']),
                era=int(row.get('era', 0)),
                session=int(row.get('session', 0)),
                
                # Transaction-level features
                total_transactions=int(row.get('total_transactions', 0)),
                successful_transactions=int(row.get('successful_transactions', 0)),
                failed_transactions=int(row.get('failed_transactions', 0)),
                avg_transaction_fee=float(row.get('avg_fee', 0)),
                max_transaction_fee=float(row.get('max_fee', 0)),
                min_transaction_fee=float(row.get('min_fee', 0)),
                
                # Network-level features
                active_accounts=int(row.get('avg_nonce', 0)),
                new_accounts=0,  # Would need account creation events
                total_volume=float(row.get('total_fee', 0)),
                avg_block_time=float(row.get('avg_block_time', 0)),
                
                # Token-level features (placeholder)
                aca_price=None,
                ausd_price=None,
                ldot_price=None,
                total_tvl=None,
                
                # Target variables
                next_block_time=float(row.get('block_time', 0)),
                next_block_size=int(prev_row['block_size']),
                transaction_success_rate=float(row.get('success_rate', 0)),
                network_activity_score=float(row.get('transaction_density', 0))
            )
            
            self.ml_features.append(features)
        
        logging.info(f"Engineered {len(self.ml_features)} ML feature sets")
    
    def create_ml_datasets(self) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
        """Create machine learning datasets"""
        logging.info("Creating ML datasets...")
        
        if not self.ml_features:
            logging.error("No ML features available")
            return pd.DataFrame(), pd.DataFrame(), pd.DataFrame(), pd.DataFrame()
        
        # Convert to DataFrame
        features_df = pd.DataFrame([asdict(feature) for feature in self.ml_features])
        
        # Separate features and targets
        feature_columns = [
            'block_number', 'block_timestamp', 'extrinsics_count', 'events_count', 
            'block_size', 'era', 'session', 'total_transactions', 'successful_transactions',
            'failed_transactions', 'avg_transaction_fee', 'max_transaction_fee', 
            'min_transaction_fee', 'active_accounts', 'new_accounts', 'total_volume', 
            'avg_block_time', 'aca_price', 'ausd_price', 'ldot_price', 'total_tvl'
        ]
        
        target_columns = [
            'next_block_time', 'next_block_size', 'transaction_success_rate', 
            'network_activity_score'
        ]
        
        # Remove rows with missing targets
        features_df = features_df.dropna(subset=target_columns)
        
        # Prepare feature matrix
        X = features_df[feature_columns].copy()
        y_next_block_time = features_df['next_block_time']
        y_next_block_size = features_df['next_block_size']
        y_success_rate = features_df['transaction_success_rate']
        y_activity_score = features_df['network_activity_score']
        
        # Handle missing values in features
        numeric_columns = X.select_dtypes(include=[np.number]).columns
        X[numeric_columns] = X[numeric_columns].fillna(0)
        
        # Scale features
        X_scaled = pd.DataFrame(
            self.scaler.fit_transform(X),
            columns=X.columns,
            index=X.index
        )
        
        logging.info(f"Created ML datasets with {len(X_scaled)} samples and {len(feature_columns)} features")
        
        return X_scaled, y_next_block_time, y_success_rate, y_activity_score
    
    def train_ml_models(self, X: pd.DataFrame, y_next_block_time: pd.Series, 
                       y_success_rate: pd.Series, y_activity_score: pd.Series) -> Dict[str, Any]:
        """Train machine learning models"""
        logging.info("Training ML models...")
        
        models = {}
        results = {}
        
        # Model 1: Predict next block time
        if len(y_next_block_time) > 10:
            X_train, X_test, y_train, y_test = train_test_split(
                X, y_next_block_time, test_size=0.2, random_state=42
            )
            
            model_next_block_time = RandomForestRegressor(n_estimators=100, random_state=42)
            model_next_block_time.fit(X_train, y_train)
            
            y_pred = model_next_block_time.predict(X_test)
            mse = mean_squared_error(y_test, y_pred)
            
            models['next_block_time'] = model_next_block_time
            results['next_block_time'] = {
                'mse': mse,
                'rmse': np.sqrt(mse),
                'feature_importance': dict(zip(X.columns, model_next_block_time.feature_importances_))
            }
            
            logging.info(f"Next block time model - RMSE: {np.sqrt(mse):.4f}")
        
        # Model 2: Predict transaction success rate
        if len(y_success_rate) > 10:
            X_train, X_test, y_train, y_test = train_test_split(
                X, y_success_rate, test_size=0.2, random_state=42
            )
            
            model_success_rate = RandomForestRegressor(n_estimators=100, random_state=42)
            model_success_rate.fit(X_train, y_train)
            
            y_pred = model_success_rate.predict(X_test)
            mse = mean_squared_error(y_test, y_pred)
            
            models['success_rate'] = model_success_rate
            results['success_rate'] = {
                'mse': mse,
                'rmse': np.sqrt(mse),
                'feature_importance': dict(zip(X.columns, model_success_rate.feature_importances_))
            }
            
            logging.info(f"Success rate model - RMSE: {np.sqrt(mse):.4f}")
        
        # Model 3: Predict network activity score
        if len(y_activity_score) > 10:
            X_train, X_test, y_train, y_test = train_test_split(
                X, y_activity_score, test_size=0.2, random_state=42
            )
            
            model_activity_score = RandomForestRegressor(n_estimators=100, random_state=42)
            model_activity_score.fit(X_train, y_train)
            
            y_pred = model_activity_score.predict(X_test)
            mse = mean_squared_error(y_test, y_pred)
            
            models['activity_score'] = model_activity_score
            results['activity_score'] = {
                'mse': mse,
                'rmse': np.sqrt(mse),
                'feature_importance': dict(zip(X.columns, model_activity_score.feature_importances_))
            }
            
            logging.info(f"Activity score model - RMSE: {np.sqrt(mse):.4f}")
        
        return {'models': models, 'results': results}
    
    def save_ml_data(self, X: pd.DataFrame, y_next_block_time: pd.Series, 
                    y_success_rate: pd.Series, y_activity_score: pd.Series,
                    models_results: Dict[str, Any]) -> None:
        """Save ML data and models"""
        logging.info("Saving ML data and models...")
        
        # Save datasets
        X.to_csv(self.output_dir / "acala_features.csv", index=False)
        y_next_block_time.to_csv(self.output_dir / "acala_target_next_block_time.csv", index=False)
        y_success_rate.to_csv(self.output_dir / "acala_target_success_rate.csv", index=False)
        y_activity_score.to_csv(self.output_dir / "acala_target_activity_score.csv", index=False)
        
        # Save models
        models = models_results['models']
        for name, model in models.items():
            with open(self.output_dir / f"acala_model_{name}.pkl", 'wb') as f:
                pickle.dump(model, f)
        
        # Save scaler
        with open(self.output_dir / "acala_scaler.pkl", 'wb') as f:
            pickle.dump(self.scaler, f)
        
        # Save results
        with open(self.output_dir / "acala_ml_results.json", 'w') as f:
            # Convert numpy types to native Python types for JSON serialization
            results = models_results['results']
            for model_name, result in results.items():
                result['feature_importance'] = {
                    k: float(v) for k, v in result['feature_importance'].items()
                }
            json.dump(results, f, indent=2, default=str)
        
        # Save feature importance plots
        self.create_feature_importance_plots(models_results['results'])
        
        logging.info(f"ML data saved to {self.output_dir}")
    
    def create_feature_importance_plots(self, results: Dict[str, Any]) -> None:
        """Create feature importance visualization plots"""
        logging.info("Creating feature importance plots...")
        
        for model_name, result in results.items():
            if 'feature_importance' in result:
                # Get top 10 features
                importance = result['feature_importance']
                top_features = sorted(importance.items(), key=lambda x: x[1], reverse=True)[:10]
                
                features, scores = zip(*top_features)
                
                plt.figure(figsize=(12, 8))
                plt.barh(range(len(features)), scores)
                plt.yticks(range(len(features)), features)
                plt.xlabel('Feature Importance')
                plt.title(f'Top 10 Feature Importance - {model_name.replace("_", " ").title()}')
                plt.gca().invert_yaxis()
                plt.tight_layout()
                
                plt.savefig(self.output_dir / f"feature_importance_{model_name}.png", dpi=300, bbox_inches='tight')
                plt.close()
    
    def generate_ml_report(self, models_results: Dict[str, Any]) -> None:
        """Generate comprehensive ML analysis report"""
        logging.info("Generating ML analysis report...")
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "data_summary": {
                "total_samples": len(self.ml_features),
                "feature_count": len(self.ml_features[0].__dict__) - 4 if self.ml_features else 0,  # Exclude targets
                "target_variables": ["next_block_time", "next_block_size", "transaction_success_rate", "network_activity_score"]
            },
            "model_performance": models_results['results'],
            "data_preprocessing": {
                "scaling_method": "StandardScaler",
                "missing_value_strategy": "fillna(0) for numeric, drop for targets",
                "feature_engineering": [
                    "Block-level aggregations",
                    "Transaction-level statistics",
                    "Network activity metrics",
                    "Time-based features"
                ]
            },
            "recommendations": [
                "Collect more historical data for better model performance",
                "Add external data sources (price feeds, TVL data)",
                "Implement real-time feature engineering pipeline",
                "Consider ensemble methods for improved predictions",
                "Add cross-validation for more robust evaluation"
            ]
        }
        
        with open(self.output_dir / "acala_ml_report.json", 'w') as f:
            json.dump(report, f, indent=2, default=str)
        
        # Create markdown report
        self.create_markdown_report(report)
    
    def create_markdown_report(self, report: Dict[str, Any]) -> None:
        """Create markdown format report"""
        markdown_content = f"""# Acala Network Machine Learning Analysis Report

Generated on: {report['timestamp']}

## Data Summary

- **Total Samples**: {report['data_summary']['total_samples']}
- **Feature Count**: {report['data_summary']['feature_count']}
- **Target Variables**: {', '.join(report['data_summary']['target_variables'])}

## Model Performance

"""
        
        for model_name, result in report['model_performance'].items():
            markdown_content += f"""### {model_name.replace('_', ' ').title()}

- **RMSE**: {result['rmse']:.4f}
- **MSE**: {result['mse']:.4f}

#### Top 5 Most Important Features:

"""
            # Get top 5 features
            importance = result['feature_importance']
            top_features = sorted(importance.items(), key=lambda x: x[1], reverse=True)[:5]
            
            for feature, score in top_features:
                markdown_content += f"- **{feature}**: {score:.4f}\n"
            
            markdown_content += "\n"
        
        markdown_content += """## Data Preprocessing

- **Scaling Method**: StandardScaler
- **Missing Value Strategy**: fillna(0) for numeric features, drop for targets

### Feature Engineering

"""
        
        for feature in report['data_preprocessing']['feature_engineering']:
            markdown_content += f"- {feature}\n"
        
        markdown_content += """

## Recommendations

"""
        
        for recommendation in report['recommendations']:
            markdown_content += f"- {recommendation}\n"
        
        with open(self.output_dir / "acala_ml_report.md", 'w') as f:
            f.write(markdown_content)
    
    def run_preparation_pipeline(self) -> None:
        """Run complete data preparation pipeline"""
        logging.info("Starting Acala data preparation pipeline...")
        
        # Load data
        if not self.load_investigation_data():
            logging.error("Failed to load investigation data")
            return
        
        # Clean and preprocess
        self.clean_and_preprocess_data()
        
        # Engineer features
        self.engineer_features()
        
        # Create ML datasets
        X, y_next_block_time, y_success_rate, y_activity_score = self.create_ml_datasets()
        
        if len(X) == 0:
            logging.error("No valid ML datasets created")
            return
        
        # Train models
        models_results = self.train_ml_models(X, y_next_block_time, y_success_rate, y_activity_score)
        
        # Save data and models
        self.save_ml_data(X, y_next_block_time, y_success_rate, y_activity_score, models_results)
        
        # Generate report
        self.generate_ml_report(models_results)
        
        logging.info("Acala data preparation pipeline completed successfully!")

def main():
    """Main function"""
    preparator = AcalaDataPreparator()
    preparator.run_preparation_pipeline()

if __name__ == "__main__":
    main()
