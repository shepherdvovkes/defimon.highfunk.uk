import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.ensemble import RandomForestRegressor, IsolationForest
from sklearn.preprocessing import StandardScaler
from xgboost import XGBRegressor
import joblib
from typing import Dict, List, Tuple, Optional
import os

# Enable Metal GPU acceleration for TensorFlow on M1
try:
    physical_devices = tf.config.list_physical_devices('GPU')
    if physical_devices:
        tf.config.experimental.set_memory_growth(physical_devices[0], True)
        print("M1 Metal GPU acceleration enabled")
except:
    print("M1 Metal GPU not available, using CPU")

class M1OptimizedModels:
    """M1-optimized ML models for blockchain data analysis"""
    
    def __init__(self):
        self.models = {}
        self.scalers = {}
        self.feature_importance = {}
        
        # M1-optimized configurations (more conservative than M4)
        self.lstm_config = {
            'units': 64,   # Smaller for M1's Neural Engine
            'layers': 2,
            'dropout': 0.3,
            'batch_size': 16,  # Smaller batch size for M1
            'lookback': 24     # Shorter lookback for memory efficiency
        }
        
        self.transformer_config = {
            'num_heads': 4,    # Fewer heads for M1
            'd_model': 256,    # Smaller model size
            'num_layers': 2,   # Fewer layers
            'dropout': 0.2
        }
        
        # M1-specific optimizations
        self.use_mixed_precision = True  # M1 handles mixed precision well
        self.memory_efficient = True     # Conservative memory usage
    
    def create_lstm_model(self, input_shape: Tuple[int, int]) -> tf.keras.Model:
        """Create M1-optimized LSTM model"""
        # Enable mixed precision for M1
        if self.use_mixed_precision:
            tf.keras.mixed_precision.set_global_policy('mixed_float16')
        
        model = tf.keras.Sequential([
            tf.keras.layers.LSTM(
                self.lstm_config['units'], 
                return_sequences=True, 
                input_shape=input_shape,
                activation='tanh',
                recurrent_dropout=0.1  # M1 handles recurrent dropout well
            ),
            tf.keras.layers.Dropout(self.lstm_config['dropout']),
            tf.keras.layers.LSTM(
                self.lstm_config['units'] // 2, 
                return_sequences=False,
                recurrent_dropout=0.1
            ),
            tf.keras.layers.Dropout(self.lstm_config['dropout']),
            tf.keras.layers.Dense(32, activation='relu'),
            tf.keras.layers.Dense(16, activation='relu'),
            tf.keras.layers.Dense(1, dtype='float32')  # Output in float32
        ])
        
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
            loss='mse',
            metrics=['mae']
        )
        
        return model
    
    def create_transformer_model(self, input_shape: Tuple[int, int]) -> tf.keras.Model:
        """Create M1-optimized Transformer model"""
        if self.use_mixed_precision:
            tf.keras.mixed_precision.set_global_policy('mixed_float16')
        
        inputs = tf.keras.layers.Input(shape=input_shape)
        
        # Multi-head attention with M1 optimizations
        attention_output = tf.keras.layers.MultiHeadAttention(
            num_heads=self.transformer_config['num_heads'],
            key_dim=self.transformer_config['d_model'],
            dropout=self.transformer_config['dropout']
        )(inputs, inputs)
        
        # Add & Norm
        attention_output = tf.keras.layers.LayerNormalization()(attention_output + inputs)
        
        # Feed forward (smaller for M1)
        ffn_output = tf.keras.Sequential([
            tf.keras.layers.Dense(self.transformer_config['d_model'] * 2, activation='relu'),
            tf.keras.layers.Dropout(self.transformer_config['dropout']),
            tf.keras.layers.Dense(self.transformer_config['d_model'])
        ])(attention_output)
        
        # Add & Norm
        ffn_output = tf.keras.layers.LayerNormalization()(ffn_output + attention_output)
        
        # Global average pooling and output
        pooled = tf.keras.layers.GlobalAveragePooling1D()(ffn_output)
        outputs = tf.keras.layers.Dense(1, dtype='float32')(pooled)
        
        model = tf.keras.Model(inputs=inputs, outputs=outputs)
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
            loss='mse',
            metrics=['mae']
        )
        
        return model
    
    def create_ensemble_model(self, n_estimators: int = 50) -> XGBRegressor:
        """Create M1-optimized ensemble model (smaller than M4)"""
        return XGBRegressor(
            n_estimators=n_estimators,
            max_depth=4,        # Smaller depth for M1
            learning_rate=0.15, # Slightly higher for faster convergence
            subsample=0.7,
            colsample_bytree=0.7,
            random_state=42,
            n_jobs=-1,          # Use all CPU cores
            tree_method='hist'  # M1 handles histogram method well
        )
    
    def create_anomaly_detector(self, contamination: float = 0.1) -> IsolationForest:
        """Create anomaly detection model optimized for M1"""
        return IsolationForest(
            contamination=contamination,
            random_state=42,
            n_jobs=-1,
            max_samples='auto'  # M1 handles auto sampling well
        )
    
    def create_lightweight_model(self) -> RandomForestRegressor:
        """Create lightweight model for M1's efficiency"""
        return RandomForestRegressor(
            n_estimators=50,
            max_depth=6,
            min_samples_split=5,
            min_samples_leaf=2,
            random_state=42,
            n_jobs=-1
        )
    
    def prepare_blockchain_features(self, df: pd.DataFrame) -> np.ndarray:
        """Prepare blockchain-specific features optimized for M1"""
        features = []
        
        # Price-based features (reduced set for M1)
        features.extend([
            df['price'].pct_change(),
            df['price'].rolling(12).mean(),  # Shorter windows for M1
            df['price'].rolling(84).std(),   # 7-day volatility (shorter)
        ])
        
        # Volume features
        features.extend([
            df['volume_24h'].pct_change(),
            df['volume_24h'].rolling(12).mean(),
        ])
        
        # DeFi-specific features
        if 'total_value_locked' in df.columns:
            features.extend([
                df['total_value_locked'].pct_change(),
            ])
        
        # Technical indicators (simplified for M1)
        features.extend([
            self._calculate_rsi(df['price']),
            self._calculate_simple_macd(df['price']),
        ])
        
        # Network metrics (if available)
        if 'gas_price' in df.columns:
            features.extend([
                df['gas_price'].pct_change(),
            ])
        
        return np.column_stack([f.fillna(0) for f in features])
    
    def _calculate_rsi(self, prices: pd.Series, period: int = 14) -> pd.Series:
        """Calculate RSI technical indicator"""
        delta = prices.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        rsi = 100 - (100 / (1 + rs))
        return rsi
    
    def _calculate_simple_macd(self, prices: pd.Series, fast: int = 12, slow: int = 26) -> pd.Series:
        """Calculate simplified MACD for M1 efficiency"""
        ema_fast = prices.ewm(span=fast).mean()
        ema_slow = prices.ewm(span=slow).mean()
        return ema_fast - ema_slow
    
    def train_price_prediction_model(self, data: pd.DataFrame, target_col: str = 'price') -> Dict:
        """Train comprehensive price prediction model optimized for M1"""
        # Prepare features
        X = self.prepare_blockchain_features(data)
        y = data[target_col].values
        
        # Remove NaN values
        mask = ~(np.isnan(X).any(axis=1) | np.isnan(y))
        X_clean = X[mask]
        y_clean = y[mask]
        
        # Split data
        split_idx = int(len(X_clean) * 0.8)
        X_train, X_test = X_clean[:split_idx], X_clean[split_idx:]
        y_train, y_test = y_clean[:split_idx], y_clean[split_idx:]
        
        # Scale features
        scaler = StandardScaler()
        X_train_scaled = scaler.fit_transform(X_train)
        X_test_scaled = scaler.transform(X_test)
        
        # Train LSTM model (smaller for M1)
        X_lstm = X_train_scaled.reshape(-1, self.lstm_config['lookback'], X_train_scaled.shape[1])
        y_lstm = y_train[self.lstm_config['lookback']:]
        
        lstm_model = self.create_lstm_model((self.lstm_config['lookback'], X_train_scaled.shape[1]))
        lstm_history = lstm_model.fit(
            X_lstm, y_lstm,
            epochs=30,  # Fewer epochs for M1
            batch_size=self.lstm_config['batch_size'],
            validation_split=0.2,
            verbose=1
        )
        
        # Train ensemble model
        ensemble_model = self.create_ensemble_model()
        ensemble_model.fit(X_train_scaled, y_train)
        
        # Train lightweight model
        lightweight_model = self.create_lightweight_model()
        lightweight_model.fit(X_train_scaled, y_train)
        
        # Evaluate models
        lstm_pred = lstm_model.predict(X_lstm)
        ensemble_pred = ensemble_model.predict(X_train_scaled)
        lightweight_pred = lightweight_model.predict(X_train_scaled)
        
        results = {
            'lstm_model': lstm_model,
            'ensemble_model': ensemble_model,
            'lightweight_model': lightweight_model,
            'scaler': scaler,
            'lstm_mae': np.mean(np.abs(lstm_pred - y_lstm)),
            'ensemble_mae': np.mean(np.abs(ensemble_pred - y_train)),
            'lightweight_mae': np.mean(np.abs(lightweight_pred - y_train)),
            'feature_importance': dict(zip(range(X_train_scaled.shape[1]), ensemble_model.feature_importances_))
        }
        
        return results
    
    def predict_price(self, model_results: Dict, new_data: pd.DataFrame, horizon: int = 24) -> np.ndarray:
        """Make price predictions using M1-optimized ensemble"""
        # Prepare features
        X = self.prepare_blockchain_features(new_data)
        X_scaled = model_results['scaler'].transform(X)
        
        # Make predictions
        lstm_pred = model_results['lstm_model'].predict(
            X_scaled.reshape(-1, self.lstm_config['lookback'], X_scaled.shape[1])
        )
        ensemble_pred = model_results['ensemble_model'].predict(X_scaled)
        lightweight_pred = model_results['lightweight_model'].predict(X_scaled)
        
        # Weighted ensemble (favor lightweight model for M1 efficiency)
        combined_pred = (
            0.3 * lstm_pred.flatten() + 
            0.4 * ensemble_pred + 
            0.3 * lightweight_pred
        )
        
        return combined_pred
    
    def detect_anomalies(self, data: pd.DataFrame, contamination: float = 0.1) -> np.ndarray:
        """Detect anomalies in blockchain data using M1-optimized approach"""
        # Prepare features
        X = self.prepare_blockchain_features(data)
        
        # Remove NaN values
        mask = ~np.isnan(X).any(axis=1)
        X_clean = X[mask]
        
        # Train anomaly detector
        detector = self.create_anomaly_detector(contamination)
        detector.fit(X_clean)
        
        # Predict anomalies
        predictions = detector.predict(X_clean)
        
        # Convert to boolean (True = anomaly)
        anomalies = predictions == -1
        
        return anomalies
    
    def train_memory_efficient_model(self, data: pd.DataFrame, target_col: str = 'price') -> Dict:
        """Train memory-efficient model specifically for M1's constraints"""
        # Use smaller feature set
        features = [
            data['price'].pct_change(),
            data['price'].rolling(6).mean(),
            data['volume_24h'].pct_change(),
            self._calculate_rsi(data['price'])
        ]
        
        X = np.column_stack([f.fillna(0) for f in features])
        y = data[target_col].values
        
        # Remove NaN values
        mask = ~(np.isnan(X).any(axis=1) | np.isnan(y))
        X_clean = X[mask]
        y_clean = y[mask]
        
        # Use very lightweight model
        model = RandomForestRegressor(
            n_estimators=25,
            max_depth=3,
            min_samples_split=10,
            random_state=42,
            n_jobs=-1
        )
        
        model.fit(X_clean, y_clean)
        
        return {
            'model': model,
            'feature_names': ['price_change', 'price_sma_6h', 'volume_change', 'rsi'],
            'mae': np.mean(np.abs(model.predict(X_clean) - y_clean))
        }
    
    def get_m1_performance_metrics(self) -> Dict:
        """Get M1-specific performance recommendations"""
        return {
            'recommended_batch_size': 16,
            'max_model_size_mb': 100,
            'optimal_lstm_units': 64,
            'optimal_transformer_heads': 4,
            'memory_efficiency_tips': [
                'Use mixed precision training',
                'Keep batch sizes small',
                'Use shorter sequence lengths',
                'Prefer CPU-optimized algorithms',
                'Use memory-efficient data types'
            ],
            'neural_engine_compatibility': [
                'LSTM layers work well',
                'Dense layers are optimized',
                'Convolutional layers supported',
                'Attention mechanisms work',
                'Avoid very large models'
            ]
        }
