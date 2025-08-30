import numpy as np
import pandas as pd
import tensorflow as tf
from sklearn.ensemble import RandomForestRegressor, IsolationForest
from sklearn.preprocessing import StandardScaler
from xgboost import XGBRegressor
import joblib
from typing import Dict, List, Tuple, Optional
import os

# Enable Metal GPU acceleration for TensorFlow
try:
    physical_devices = tf.config.list_physical_devices('GPU')
    if physical_devices:
        tf.config.experimental.set_memory_growth(physical_devices[0], True)
        print("Metal GPU acceleration enabled")
except:
    print("Metal GPU not available, using CPU")

class M4OptimizedModels:
    """M4-optimized ML models for blockchain data analysis"""
    
    def __init__(self):
        self.models = {}
        self.scalers = {}
        self.feature_importance = {}
        
        # M4-optimized configurations
        self.lstm_config = {
            'units': 128,  # Optimized for Neural Engine
            'layers': 2,
            'dropout': 0.2,
            'batch_size': 32,
            'lookback': 48
        }
        
        self.transformer_config = {
            'num_heads': 8,
            'd_model': 512,
            'num_layers': 4,
            'dropout': 0.1
        }
    
    def create_lstm_model(self, input_shape: Tuple[int, int]) -> tf.keras.Model:
        """Create M4-optimized LSTM model"""
        model = tf.keras.Sequential([
            tf.keras.layers.LSTM(
                self.lstm_config['units'], 
                return_sequences=True, 
                input_shape=input_shape,
                activation='tanh'
            ),
            tf.keras.layers.Dropout(self.lstm_config['dropout']),
            tf.keras.layers.LSTM(
                self.lstm_config['units'] // 2, 
                return_sequences=False
            ),
            tf.keras.layers.Dropout(self.lstm_config['dropout']),
            tf.keras.layers.Dense(64, activation='relu'),
            tf.keras.layers.Dense(32, activation='relu'),
            tf.keras.layers.Dense(1)
        ])
        
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
            loss='mse',
            metrics=['mae']
        )
        
        return model
    
    def create_transformer_model(self, input_shape: Tuple[int, int]) -> tf.keras.Model:
        """Create M4-optimized Transformer model"""
        inputs = tf.keras.layers.Input(shape=input_shape)
        
        # Multi-head attention
        attention_output = tf.keras.layers.MultiHeadAttention(
            num_heads=self.transformer_config['num_heads'],
            key_dim=self.transformer_config['d_model']
        )(inputs, inputs)
        
        # Add & Norm
        attention_output = tf.keras.layers.LayerNormalization()(attention_output + inputs)
        
        # Feed forward
        ffn_output = tf.keras.Sequential([
            tf.keras.layers.Dense(self.transformer_config['d_model'] * 4, activation='relu'),
            tf.keras.layers.Dropout(self.transformer_config['dropout']),
            tf.keras.layers.Dense(self.transformer_config['d_model'])
        ])(attention_output)
        
        # Add & Norm
        ffn_output = tf.keras.layers.LayerNormalization()(ffn_output + attention_output)
        
        # Global average pooling and output
        pooled = tf.keras.layers.GlobalAveragePooling1D()(ffn_output)
        outputs = tf.keras.layers.Dense(1)(pooled)
        
        model = tf.keras.Model(inputs=inputs, outputs=outputs)
        model.compile(
            optimizer=tf.keras.optimizers.Adam(learning_rate=0.0001),
            loss='mse',
            metrics=['mae']
        )
        
        return model
    
    def create_ensemble_model(self, n_estimators: int = 100) -> XGBRegressor:
        """Create M4-optimized ensemble model"""
        return XGBRegressor(
            n_estimators=n_estimators,
            max_depth=6,
            learning_rate=0.1,
            subsample=0.8,
            colsample_bytree=0.8,
            random_state=42,
            n_jobs=-1  # Use all CPU cores
        )
    
    def create_anomaly_detector(self, contamination: float = 0.1) -> IsolationForest:
        """Create anomaly detection model"""
        return IsolationForest(
            contamination=contamination,
            random_state=42,
            n_jobs=-1
        )
    
    def prepare_blockchain_features(self, df: pd.DataFrame) -> np.ndarray:
        """Prepare blockchain-specific features for ML"""
        features = []
        
        # Price-based features
        features.extend([
            df['price'].pct_change(),
            df['price'].rolling(24).mean(),
            df['price'].rolling(168).std(),  # 7-day volatility
            df['price'].rolling(24).max() / df['price'].rolling(24).min()
        ])
        
        # Volume features
        features.extend([
            df['volume_24h'].pct_change(),
            df['volume_24h'].rolling(24).mean(),
            df['volume_24h'].rolling(168).std()
        ])
        
        # DeFi-specific features
        if 'total_value_locked' in df.columns:
            features.extend([
                df['total_value_locked'].pct_change(),
                df['total_value_locked'].rolling(24).mean()
            ])
        
        # Technical indicators
        features.extend([
            self._calculate_rsi(df['price']),
            self._calculate_macd(df['price']),
            self._calculate_bollinger_bands(df['price'])
        ])
        
        # Network metrics (if available)
        if 'gas_price' in df.columns:
            features.extend([
                df['gas_price'].pct_change(),
                df['gas_price'].rolling(24).mean()
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
    
    def _calculate_macd(self, prices: pd.Series, fast: int = 12, slow: int = 26, signal: int = 9) -> pd.Series:
        """Calculate MACD technical indicator"""
        ema_fast = prices.ewm(span=fast).mean()
        ema_slow = prices.ewm(span=slow).mean()
        macd = ema_fast - ema_slow
        signal_line = macd.ewm(span=signal).mean()
        return macd - signal_line
    
    def _calculate_bollinger_bands(self, prices: pd.Series, period: int = 20, std_dev: int = 2) -> pd.Series:
        """Calculate Bollinger Bands"""
        sma = prices.rolling(window=period).mean()
        std = prices.rolling(window=period).std()
        upper_band = sma + (std * std_dev)
        lower_band = sma - (std * std_dev)
        return (prices - lower_band) / (upper_band - lower_band)
    
    def train_price_prediction_model(self, data: pd.DataFrame, target_col: str = 'price') -> Dict:
        """Train comprehensive price prediction model"""
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
        
        # Train LSTM model
        X_lstm = X_train_scaled.reshape(-1, self.lstm_config['lookback'], X_train_scaled.shape[1])
        y_lstm = y_train[self.lstm_config['lookback']:]
        
        lstm_model = self.create_lstm_model((self.lstm_config['lookback'], X_train_scaled.shape[1]))
        lstm_history = lstm_model.fit(
            X_lstm, y_lstm,
            epochs=50,
            batch_size=self.lstm_config['batch_size'],
            validation_split=0.2,
            verbose=1
        )
        
        # Train ensemble model
        ensemble_model = self.create_ensemble_model()
        ensemble_model.fit(X_train_scaled, y_train)
        
        # Evaluate models
        lstm_pred = lstm_model.predict(X_lstm)
        ensemble_pred = ensemble_model.predict(X_train_scaled)
        
        results = {
            'lstm_model': lstm_model,
            'ensemble_model': ensemble_model,
            'scaler': scaler,
            'lstm_mae': np.mean(np.abs(lstm_pred - y_lstm)),
            'ensemble_mae': np.mean(np.abs(ensemble_pred - y_train)),
            'feature_importance': dict(zip(range(X_train_scaled.shape[1]), ensemble_model.feature_importances_))
        }
        
        return results
    
    def predict_price(self, model_results: Dict, new_data: pd.DataFrame, horizon: int = 24) -> np.ndarray:
        """Make price predictions"""
        # Prepare features
        X = self.prepare_blockchain_features(new_data)
        X_scaled = model_results['scaler'].transform(X)
        
        # Make predictions
        lstm_pred = model_results['lstm_model'].predict(
            X_scaled.reshape(-1, self.lstm_config['lookback'], X_scaled.shape[1])
        )
        ensemble_pred = model_results['ensemble_model'].predict(X_scaled)
        
        # Combine predictions (simple average)
        combined_pred = (lstm_pred.flatten() + ensemble_pred) / 2
        
        return combined_pred
    
    def detect_anomalies(self, data: pd.DataFrame, contamination: float = 0.1) -> np.ndarray:
        """Detect anomalies in blockchain data"""
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
