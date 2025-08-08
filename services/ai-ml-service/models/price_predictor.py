import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
import joblib
from typing import Dict, List, Tuple
import os

class PricePredictionModel:
    def __init__(self):
        self.models = {
            "short_term": None,  # LSTM for 1h-24h predictions
            "medium_term": None, # Random Forest for 1d-7d predictions
            "long_term": None    # Ensemble for 1w-1m predictions
        }
        self.scalers = {}
        self.feature_columns = [
            'price', 'volume_24h', 'market_cap', 'total_value_locked',
            'trading_volume', 'volatility_7d', 'rsi', 'macd', 'bollinger_bands'
        ]
        self.model_path = os.getenv("MODEL_STORAGE_PATH", "/app/models")
    
    def prepare_features(self, df: pd.DataFrame) -> np.ndarray:
        """Prepare features for model training/prediction"""
        # Technical indicators
        df['rsi'] = self._calculate_rsi(df['price'])
        df['macd'] = self._calculate_macd(df['price'])
        df['volatility_7d'] = df['price'].rolling(168).std()  # 7 days in hours
        df['volume_sma'] = df['volume_24h'].rolling(24).mean()
        df['price_sma_short'] = df['price'].rolling(12).mean()
        df['price_sma_long'] = df['price'].rolling(48).mean()
        
        # DeFi-specific features
        df['tvl_change'] = df['total_value_locked'].pct_change()
        df['utilization_rate'] = df['total_borrowed'] / df['total_deposited']
        df['yield_rate'] = df['annual_percentage_yield']
        
        # Market sentiment features
        df['price_momentum'] = df['price'] / df['price'].shift(24) - 1
        df['volume_momentum'] = df['volume_24h'] / df['volume_24h'].shift(24) - 1
        
        return df[self.feature_columns].fillna(0).values
    
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
    
    def train_short_term_model(self, data: np.ndarray, targets: np.ndarray):
        """Train LSTM model for short-term predictions (1h-24h)"""
        # Reshape data for LSTM [samples, timesteps, features]
        X = []
        y = []
        lookback = 48  # 48 hours of data
        
        for i in range(lookback, len(data)):
            X.append(data[i-lookback:i])
            y.append(targets[i])
        
        X, y = np.array(X), np.array(y)
        
        # Scale features
        scaler = StandardScaler()
        X_scaled = scaler.fit_transform(X.reshape(-1, X.shape[-1])).reshape(X.shape)
        self.scalers['short_term'] = scaler
        
        # Build LSTM model
        model = Sequential([
            LSTM(128, return_sequences=True, input_shape=(lookback, len(self.feature_columns))),
            Dropout(0.2),
            LSTM(64, return_sequences=False),
            Dropout(0.2),
            Dense(32, activation='relu'),
            Dense(1)
        ])
        
        model.compile(optimizer='adam', loss='mse', metrics=['mae'])
        model.fit(X_scaled, y, epochs=100, batch_size=32, validation_split=0.2, verbose=0)
        
        self.models['short_term'] = model
        
        # Save model
        model.save(f"{self.model_path}/short_term_lstm.h5")
        joblib.dump(scaler, f"{self.model_path}/short_term_scaler.pkl")
        
    def train_medium_term_model(self, data: np.ndarray, targets: np.ndarray):
        """Train Random Forest model for medium-term predictions (1d-7d)"""
        scaler = StandardScaler()
        data_scaled = scaler.fit_transform(data)
        self.scalers['medium_term'] = scaler
        
        model = RandomForestRegressor(
            n_estimators=100,
            max_depth=10,
            random_state=42
        )
        
        model.fit(data_scaled, targets)
        self.models['medium_term'] = model
        
        # Save model
        joblib.dump(model, f"{self.model_path}/medium_term_rf.pkl")
        joblib.dump(scaler, f"{self.model_path}/medium_term_scaler.pkl")
    
    def load_models(self):
        """Load pre-trained models"""
        try:
            # Load short-term LSTM model
            if os.path.exists(f"{self.model_path}/short_term_lstm.h5"):
                self.models['short_term'] = Sequential()
                self.models['short_term'].load_weights(f"{self.model_path}/short_term_lstm.h5")
                self.scalers['short_term'] = joblib.load(f"{self.model_path}/short_term_scaler.pkl")
            
            # Load medium-term Random Forest model
            if os.path.exists(f"{self.model_path}/medium_term_rf.pkl"):
                self.models['medium_term'] = joblib.load(f"{self.model_path}/medium_term_rf.pkl")
                self.scalers['medium_term'] = joblib.load(f"{self.model_path}/medium_term_scaler.pkl")
                
        except Exception as e:
            print(f"Error loading models: {e}")
    
    def predict_price(self, data: np.ndarray, timeframe: str) -> Dict:
        """Predict price for given timeframe"""
        model = self.models[timeframe]
        scaler = self.scalers[timeframe]
        
        if model is None or scaler is None:
            return {
                "predicted_price": 0.0,
                "confidence": 0.0,
                "timeframe": timeframe,
                "error": "Model not loaded"
            }
        
        if timeframe == "short_term":
            # LSTM prediction
            data_scaled = scaler.transform(data.reshape(-1, data.shape[-1])).reshape(data.shape)
            prediction = model.predict(data_scaled[-1:])
            confidence = self._calculate_prediction_confidence(data_scaled, prediction)
        else:
            # Traditional ML prediction
            data_scaled = scaler.transform(data[-1:])
            prediction = model.predict(data_scaled)
            confidence = model.predict_proba(data_scaled).max() if hasattr(model, 'predict_proba') else 0.7
        
        return {
            "predicted_price": float(prediction[0]),
            "confidence": float(confidence),
            "timeframe": timeframe,
            "timestamp": pd.Timestamp.now().isoformat()
        }
    
    def _calculate_prediction_confidence(self, data: np.ndarray, prediction: np.ndarray) -> float:
        """Calculate confidence score for prediction"""
        # Simple confidence based on data variance
        variance = np.var(data)
        confidence = max(0.1, min(0.9, 1.0 - variance / 1000))
        return confidence
