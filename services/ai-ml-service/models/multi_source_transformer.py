import torch
import torch.nn as nn
import torch.nn.functional as F
from typing import Dict, List, Tuple, Optional
import numpy as np
from transformers import AutoTokenizer, AutoModel
import logging

logger = logging.getLogger(__name__)

class MultiSourceTransformer(nn.Module):
    """
    Multi-source transformer model for blockchain data analysis
    Combines blockchain, GitHub, social media, and news data
    """
    
    def __init__(self, config: Dict):
        super().__init__()
        self.config = config
        
        # Initialize encoders for different data sources
        self._init_blockchain_encoder()
        self._init_github_encoder()
        self._init_social_encoder()
        self._init_news_encoder()
        
        # Fusion layer for combining all sources
        self._init_fusion_layer()
        
        # Output layers for different tasks
        self._init_output_layers()
        
        # Initialize weights
        self.apply(self._init_weights)
    
    def _init_blockchain_encoder(self):
        """Initialize blockchain data encoder"""
        self.blockchain_encoder = nn.TransformerEncoder(
            nn.TransformerEncoderLayer(
                d_model=self.config.get('blockchain_dim', 512),
                nhead=self.config.get('blockchain_heads', 8),
                dim_feedforward=self.config.get('blockchain_ff_dim', 2048),
                dropout=self.config.get('dropout', 0.1),
                batch_first=True
            ),
            num_layers=self.config.get('blockchain_layers', 6)
        )
        
        # Input projection for blockchain features
        self.blockchain_projection = nn.Linear(
            self.config.get('blockchain_input_dim', 50),
            self.config.get('blockchain_dim', 512)
        )
    
    def _init_github_encoder(self):
        """Initialize GitHub data encoder"""
        self.github_encoder = nn.TransformerEncoder(
            nn.TransformerEncoderLayer(
                d_model=self.config.get('github_dim', 256),
                nhead=self.config.get('github_heads', 4),
                dim_feedforward=self.config.get('github_ff_dim', 1024),
                dropout=self.config.get('dropout', 0.1),
                batch_first=True
            ),
            num_layers=self.config.get('github_layers', 4)
        )
        
        # Input projection for GitHub features
        self.github_projection = nn.Linear(
            self.config.get('github_input_dim', 20),
            self.config.get('github_dim', 256)
        )
    
    def _init_social_encoder(self):
        """Initialize social media data encoder"""
        self.social_encoder = nn.TransformerEncoder(
            nn.TransformerEncoderLayer(
                d_model=self.config.get('social_dim', 256),
                nhead=self.config.get('social_heads', 4),
                dim_feedforward=self.config.get('social_ff_dim', 1024),
                dropout=self.config.get('dropout', 0.1),
                batch_first=True
            ),
            num_layers=self.config.get('social_layers', 4)
        )
        
        # Input projection for social features
        self.social_projection = nn.Linear(
            self.config.get('social_input_dim', 30),
            self.config.get('social_dim', 256)
        )
    
    def _init_news_encoder(self):
        """Initialize news data encoder"""
        self.news_encoder = nn.TransformerEncoder(
            nn.TransformerEncoderLayer(
                d_model=self.config.get('news_dim', 256),
                nhead=self.config.get('news_heads', 4),
                dim_feedforward=self.config.get('news_ff_dim', 1024),
                dropout=self.config.get('dropout', 0.1),
                batch_first=True
            ),
            num_layers=self.config.get('news_layers', 4)
        )
        
        # Input projection for news features
        self.news_projection = nn.Linear(
            self.config.get('news_input_dim', 25),
            self.config.get('news_dim', 256)
        )
    
    def _init_fusion_layer(self):
        """Initialize fusion layer for combining all sources"""
        fusion_dim = self.config.get('fusion_dim', 512)
        
        # Project all encoders to same dimension
        self.github_to_fusion = nn.Linear(
            self.config.get('github_dim', 256), fusion_dim
        )
        self.social_to_fusion = nn.Linear(
            self.config.get('social_dim', 256), fusion_dim
        )
        self.news_to_fusion = nn.Linear(
            self.config.get('news_dim', 256), fusion_dim
        )
        
        # Multi-head attention for fusion
        self.fusion_attention = nn.MultiheadAttention(
            embed_dim=fusion_dim,
            num_heads=self.config.get('fusion_heads', 8),
            dropout=self.config.get('dropout', 0.1),
            batch_first=True
        )
        
        # Layer normalization
        self.fusion_norm = nn.LayerNorm(fusion_dim)
        
        # Feed-forward network for fusion
        self.fusion_ffn = nn.Sequential(
            nn.Linear(fusion_dim, fusion_dim * 4),
            nn.ReLU(),
            nn.Dropout(self.config.get('dropout', 0.1)),
            nn.Linear(fusion_dim * 4, fusion_dim)
        )
    
    def _init_output_layers(self):
        """Initialize output layers for different tasks"""
        fusion_dim = self.config.get('fusion_dim', 512)
        
        # Price prediction (regression)
        self.price_predictor = nn.Sequential(
            nn.Linear(fusion_dim, fusion_dim // 2),
            nn.ReLU(),
            nn.Dropout(self.config.get('dropout', 0.1)),
            nn.Linear(fusion_dim // 2, 1)
        )
        
        # Risk assessment (multi-class classification)
        self.risk_scorer = nn.Sequential(
            nn.Linear(fusion_dim, fusion_dim // 2),
            nn.ReLU(),
            nn.Dropout(self.config.get('dropout', 0.1)),
            nn.Linear(fusion_dim // 2, 5)  # 5 risk categories
        )
        
        # Sentiment analysis (3-class classification)
        self.sentiment_analyzer = nn.Sequential(
            nn.Linear(fusion_dim, fusion_dim // 2),
            nn.ReLU(),
            nn.Dropout(self.config.get('dropout', 0.1)),
            nn.Linear(fusion_dim // 2, 3)  # Positive, Neutral, Negative
        )
        
        # Trend prediction (binary classification)
        self.trend_predictor = nn.Sequential(
            nn.Linear(fusion_dim, fusion_dim // 2),
            nn.ReLU(),
            nn.Dropout(self.config.get('dropout', 0.1)),
            nn.Linear(fusion_dim // 2, 1),
            nn.Sigmoid()
        )
    
    def _init_weights(self, module):
        """Initialize model weights"""
        if isinstance(module, nn.Linear):
            nn.init.xavier_uniform_(module.weight)
            if module.bias is not None:
                nn.init.zeros_(module.bias)
        elif isinstance(module, nn.LayerNorm):
            nn.init.ones_(module.weight)
            nn.init.zeros_(module.bias)
    
    def forward(self, batch: Dict[str, torch.Tensor]) -> Dict[str, torch.Tensor]:
        """
        Forward pass through the multi-source transformer
        
        Args:
            batch: Dictionary containing data from all sources
                - blockchain: [batch_size, seq_len, blockchain_features]
                - github: [batch_size, seq_len, github_features]
                - social: [batch_size, seq_len, social_features]
                - news: [batch_size, seq_len, news_features]
        
        Returns:
            Dictionary containing predictions for all tasks
        """
        # Encode blockchain data
        blockchain_features = self._encode_blockchain(batch['blockchain'])
        
        # Encode GitHub data
        github_features = self._encode_github(batch['github'])
        
        # Encode social media data
        social_features = self._encode_social(batch['social'])
        
        # Encode news data
        news_features = self._encode_news(batch['news'])
        
        # Fuse all features
        fused_features = self._fuse_features(
            blockchain_features, github_features, social_features, news_features
        )
        
        # Generate predictions
        predictions = self._generate_predictions(fused_features)
        
        return predictions
    
    def _encode_blockchain(self, blockchain_data: torch.Tensor) -> torch.Tensor:
        """Encode blockchain time series data"""
        # Project to encoder dimension
        projected = self.blockchain_projection(blockchain_data)
        
        # Add positional encoding if needed
        if self.config.get('use_positional_encoding', True):
            projected = self._add_positional_encoding(projected)
        
        # Encode with transformer
        encoded = self.blockchain_encoder(projected)
        
        # Global average pooling
        pooled = torch.mean(encoded, dim=1)
        
        return pooled
    
    def _encode_github(self, github_data: torch.Tensor) -> torch.Tensor:
        """Encode GitHub development activity data"""
        # Project to encoder dimension
        projected = self.github_projection(github_data)
        
        # Add positional encoding if needed
        if self.config.get('use_positional_encoding', True):
            projected = self._add_positional_encoding(projected)
        
        # Encode with transformer
        encoded = self.github_encoder(projected)
        
        # Global average pooling
        pooled = torch.mean(encoded, dim=1)
        
        return pooled
    
    def _encode_social(self, social_data: torch.Tensor) -> torch.Tensor:
        """Encode social media sentiment data"""
        # Project to encoder dimension
        projected = self.social_projection(social_data)
        
        # Add positional encoding if needed
        if self.config.get('use_positional_encoding', True):
            projected = self._add_positional_encoding(projected)
        
        # Encode with transformer
        encoded = self.social_encoder(projected)
        
        # Global average pooling
        pooled = torch.mean(encoded, dim=1)
        
        return pooled
    
    def _encode_news(self, news_data: torch.Tensor) -> torch.Tensor:
        """Encode news and media data"""
        # Project to encoder dimension
        projected = self.news_projection(news_data)
        
        # Add positional encoding if needed
        if self.config.get('use_positional_encoding', True):
            projected = self._add_positional_encoding(projected)
        
        # Encode with transformer
        encoded = self.news_encoder(projected)
        
        # Global average pooling
        pooled = torch.mean(encoded, dim=1)
        
        return pooled
    
    def _add_positional_encoding(self, x: torch.Tensor) -> torch.Tensor:
        """Add positional encoding to input tensor"""
        seq_len, d_model = x.size(1), x.size(2)
        
        # Create positional encoding
        pe = torch.zeros(seq_len, d_model)
        position = torch.arange(0, seq_len).unsqueeze(1).float()
        
        div_term = torch.exp(torch.arange(0, d_model, 2).float() * 
                           -(np.log(10000.0) / d_model))
        
        pe[:, 0::2] = torch.sin(position * div_term)
        pe[:, 1::2] = torch.cos(position * div_term)
        
        # Add to input
        return x + pe.unsqueeze(0).to(x.device)
    
    def _fuse_features(self, blockchain: torch.Tensor, github: torch.Tensor,
                      social: torch.Tensor, news: torch.Tensor) -> torch.Tensor:
        """Fuse features from all sources using attention mechanism"""
        # Project all features to fusion dimension
        github_fused = self.github_to_fusion(github)
        social_fused = self.social_to_fusion(social)
        news_fused = self.news_to_fusion(news)
        
        # Stack all features (blockchain is already in correct dimension)
        all_features = torch.stack([blockchain, github_fused, social_fused, news_fused], dim=1)
        
        # Apply multi-head attention for fusion
        fused, _ = self.fusion_attention(all_features, all_features, all_features)
        
        # Add residual connection and normalize
        fused = self.fusion_norm(fused + all_features)
        
        # Apply feed-forward network
        ffn_output = self.fusion_ffn(fused)
        
        # Add residual connection and normalize
        fused = self.fusion_norm(ffn_output + fused)
        
        # Global average pooling across sources
        final_features = torch.mean(fused, dim=1)
        
        return final_features
    
    def _generate_predictions(self, features: torch.Tensor) -> Dict[str, torch.Tensor]:
        """Generate predictions for all tasks"""
        predictions = {
            'price': self.price_predictor(features),
            'risk': self.risk_scorer(features),
            'sentiment': self.sentiment_analyzer(features),
            'trend': self.trend_predictor(features)
        }
        
        return predictions
    
    def get_attention_weights(self, batch: Dict[str, torch.Tensor]) -> Dict[str, torch.Tensor]:
        """Get attention weights for interpretability"""
        # This method can be used for model interpretability
        # Implementation would return attention weights from each encoder
        pass


class MultiSourceLoss(nn.Module):
    """Multi-task loss function for the multi-source model"""
    
    def __init__(self, config: Dict):
        super().__init__()
        self.config = config
        
        # Loss weights for different tasks
        self.price_weight = config.get('price_loss_weight', 1.0)
        self.risk_weight = config.get('risk_loss_weight', 1.0)
        self.sentiment_weight = config.get('sentiment_loss_weight', 1.0)
        self.trend_weight = config.get('trend_loss_weight', 1.0)
        
        # Loss functions
        self.mse_loss = nn.MSELoss()
        self.cross_entropy_loss = nn.CrossEntropyLoss()
        self.bce_loss = nn.BCELoss()
    
    def forward(self, predictions: Dict[str, torch.Tensor], 
                targets: Dict[str, torch.Tensor]) -> Dict[str, torch.Tensor]:
        """Calculate multi-task loss"""
        losses = {}
        
        # Price prediction loss (MSE)
        if 'price' in predictions and 'price' in targets:
            losses['price'] = self.mse_loss(predictions['price'], targets['price'])
        
        # Risk assessment loss (Cross-entropy)
        if 'risk' in predictions and 'risk' in targets:
            losses['risk'] = self.cross_entropy_loss(predictions['risk'], targets['risk'])
        
        # Sentiment analysis loss (Cross-entropy)
        if 'sentiment' in predictions and 'sentiment' in targets:
            losses['sentiment'] = self.cross_entropy_loss(predictions['sentiment'], targets['sentiment'])
        
        # Trend prediction loss (Binary cross-entropy)
        if 'trend' in predictions and 'trend' in targets:
            losses['trend'] = self.bce_loss(predictions['trend'], targets['trend'])
        
        # Weighted sum of all losses
        total_loss = (
            self.price_weight * losses.get('price', 0) +
            self.risk_weight * losses.get('risk', 0) +
            self.sentiment_weight * losses.get('sentiment', 0) +
            self.trend_weight * losses.get('trend', 0)
        )
        
        losses['total'] = total_loss
        
        return losses


def create_multi_source_model(config: Dict) -> MultiSourceTransformer:
    """Factory function to create multi-source transformer model"""
    return MultiSourceTransformer(config)


def create_multi_source_loss(config: Dict) -> MultiSourceLoss:
    """Factory function to create multi-task loss function"""
    return MultiSourceLoss(config)
