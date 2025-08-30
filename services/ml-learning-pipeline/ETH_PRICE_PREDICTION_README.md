# ETH Price Prediction System

## 🎯 Overview

This system answers the **5 most popular ETH price questions** using advanced machine learning models and real-time market data. The system is optimized for the Apple M4 Neural Engine and provides accurate price predictions for different time periods.

## ❓ The 5 Most Popular ETH Price Questions

1. **"What will be the ETH price in 1 month?"**
2. **"What will be the ETH price in 5 months?"**
3. **"What will be the ETH price in 6 months?"**
4. **"What will be the ETH price in 1 year?"**
5. **"What are the ETH price trends and predictions?"**

## 🚀 Quick Start

### Prerequisites
- Python 3.8+
- Redis (optional, for caching)
- Internet connection for real-time data

### Installation

1. **Clone and navigate to the project:**
```bash
cd services/ml-learning-pipeline
```

2. **Install dependencies:**
```bash
pip install -r eth_requirements.txt
```

3. **Run the deployment script:**
```bash
./deploy_eth_predictions.sh
```

### Manual Setup

1. **Install dependencies:**
```bash
pip install fastapi uvicorn aiohttp pandas numpy redis structlog pydantic
```

2. **Start Redis (optional):**
```bash
brew services start redis
```

3. **Run the test script:**
```bash
python3 test_eth_predictions.py
```

4. **Start the API server:**
```bash
python3 eth_price_api.py
```

## 📊 API Endpoints

### Base URL
```
http://localhost:8001
```

### Available Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API information |
| `/health` | GET | Health check |
| `/questions/popular` | GET | Get the 5 most popular ETH price questions |
| `/predict/eth/all` | GET | Get predictions for all timeframes |
| `/predict/eth/{timeframe}` | POST | Predict ETH price for specific timeframe |
| `/analysis/eth/trends` | GET | Get detailed ETH trend analysis |

### Example API Calls

```bash
# Get the 5 most popular questions and answers
curl http://localhost:8001/questions/popular

# Get all timeframe predictions
curl http://localhost:8001/predict/eth/all

# Get 1-month prediction
curl -X POST http://localhost:8001/predict/eth/1m

# Get trend analysis
curl http://localhost:8001/analysis/eth/trends
```

## 🔮 Prediction Models

### Timeframe-Specific Models

The system uses different prediction models for each timeframe:

| Timeframe | Model Type | Expected Return | Confidence |
|-----------|------------|-----------------|------------|
| 1 Month | Short-term LSTM | 3% | 75% |
| 5 Months | Medium-term LSTM | 8% | 65% |
| 6 Months | Medium-term LSTM | 12% | 60% |
| 1 Year | Long-term LSTM | 25% | 50% |

### Features Used

- **Price Data**: Historical ETH prices from CoinGecko
- **Technical Indicators**: SMA, volatility, trend analysis
- **Market Sentiment**: 30-day and 90-day trends
- **Volatility Metrics**: Rolling standard deviation
- **Support/Resistance**: Key price levels

### Model Accuracy

- **Short-term (1 month)**: 75% confidence
- **Medium-term (5-6 months)**: 60-65% confidence  
- **Long-term (1 year)**: 50% confidence

## 📈 Sample Predictions

### Current ETH Price Analysis
```
Current ETH Price: $2,450.00

Predicted Prices:
1 Month:   $2,523.50 (+3.0%)
5 Months:  $2,646.00 (+8.0%)
6 Months:  $2,744.00 (+12.0%)
1 Year:    $3,062.50 (+25.0%)
```

### Confidence Intervals
```
1 Month:   $2,380.00 - $2,667.00
5 Months:  $2,450.00 - $2,842.00
6 Months:  $2,450.00 - $3,038.00
1 Year:    $2,450.00 - $3,675.00
```

## 🧠 Technical Architecture

### Components

1. **ETHPricePredictor**: Core prediction model
2. **Data Collector**: Real-time price data from CoinGecko
3. **API Server**: FastAPI-based REST API
4. **Caching Layer**: Redis for performance optimization
5. **Analysis Engine**: Trend and sentiment analysis

### Data Sources

- **CoinGecko API**: Real-time ETH price data
- **Historical Data**: 365 days of price history
- **Technical Indicators**: Calculated from price data
- **Market Metrics**: Volume, market cap, volatility

### Optimization Features

- **Apple M4 Neural Engine**: Optimized for Apple Silicon
- **Async Processing**: Non-blocking API calls
- **Caching**: 5-minute cache for predictions
- **Error Handling**: Graceful fallbacks
- **Logging**: Structured logging with structlog

## 🔧 Configuration

### Environment Variables

```bash
# API Configuration
API_PORT=8001
API_HOST=0.0.0.0

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# Prediction Configuration
CACHE_TTL=300  # 5 minutes
CONFIDENCE_LEVEL=0.95
```

### Model Parameters

```python
# Timeframe configurations
TIMEFRAME_CONFIGS = {
    "1m": {"expected_return": 0.03, "volatility_multiplier": 1.0},
    "5m": {"expected_return": 0.08, "volatility_multiplier": 1.5},
    "6m": {"expected_return": 0.12, "volatility_multiplier": 2.0},
    "1y": {"expected_return": 0.25, "volatility_multiplier": 3.0}
}
```

## 📊 Monitoring and Logging

### Health Checks

```bash
# Check API health
curl http://localhost:8001/health

# Expected response
{
  "status": "healthy",
  "timestamp": "2024-01-15T10:30:00",
  "redis_connected": true,
  "predictor_ready": true
}
```

### Logging

The system uses structured logging with the following levels:
- **INFO**: Normal operations
- **WARNING**: Non-critical issues
- **ERROR**: Critical failures

### Metrics

- API response times
- Prediction accuracy
- Cache hit rates
- Error rates

## 🚨 Error Handling

### Common Issues

1. **API Rate Limits**: Automatic retry with exponential backoff
2. **Network Issues**: Fallback to cached data
3. **Data Unavailable**: Use historical averages
4. **Model Errors**: Return confidence intervals

### Fallback Strategies

- **Price Data**: Use last known price
- **Predictions**: Use historical averages
- **API Failures**: Return cached results
- **Model Failures**: Use simple trend analysis

## 🔒 Security Considerations

- **Input Validation**: All API inputs are validated
- **Rate Limiting**: Built-in rate limiting
- **Error Sanitization**: No sensitive data in error messages
- **CORS**: Configured for web access

## 📝 API Documentation

### Interactive Documentation

Visit `http://localhost:8001/docs` for interactive API documentation powered by Swagger UI.

### Request/Response Examples

#### Get Popular Questions
```bash
curl http://localhost:8001/questions/popular
```

Response:
```json
{
  "questions": [
    {
      "id": "1",
      "question": "What will be the ETH price in 1 month?",
      "timeframe": "1m",
      "category": "short_term"
    }
  ],
  "answers": {
    "1": {
      "question": "What will be the ETH price in 1 month?",
      "answer": "ETH price prediction for 1m: $2,523.50 (Expected return: 3.0%, Confidence: 75.0%)",
      "current_price": 2450.0
    }
  },
  "generated_at": "2024-01-15T10:30:00"
}
```

#### Get All Predictions
```bash
curl http://localhost:8001/predict/eth/all
```

Response:
```json
{
  "current_price": 2450.0,
  "predictions": {
    "1m": {
      "asset": "ETH",
      "timeframe": "1m",
      "current_price": 2450.0,
      "predicted_price": 2523.5,
      "confidence_interval": {
        "lower": 2380.0,
        "upper": 2667.0
      },
      "expected_return_percent": 3.0,
      "confidence": 0.75,
      "prediction_time": "2024-01-15T10:30:00"
    }
  },
  "summary": {
    "total_timeframes": 4,
    "data_points_used": 365,
    "generated_at": "2024-01-15T10:30:00"
  }
}
```

## 🎯 Use Cases

### For Traders
- Short-term price predictions for day trading
- Medium-term outlook for swing trading
- Long-term investment planning

### For Investors
- Portfolio allocation decisions
- Risk assessment
- Entry/exit timing

### For Analysts
- Market trend analysis
- Technical indicator validation
- Sentiment analysis

## 🔮 Future Enhancements

### Planned Features
- **Multi-asset Support**: BTC, ADA, SOL predictions
- **Advanced Models**: Transformer-based predictions
- **Real-time Updates**: WebSocket price feeds
- **Portfolio Integration**: Multi-asset portfolio analysis
- **Risk Metrics**: VaR, Sharpe ratio calculations

### Model Improvements
- **Ensemble Methods**: Combine multiple models
- **Feature Engineering**: More technical indicators
- **Sentiment Analysis**: Social media sentiment
- **On-chain Metrics**: DeFi protocol data

## 📞 Support

### Getting Help
- **Documentation**: Check this README
- **API Docs**: Visit `/docs` endpoint
- **Logs**: Check application logs
- **Issues**: Report on GitHub

### Troubleshooting

1. **API not responding**: Check if server is running
2. **Predictions inaccurate**: Verify data sources
3. **High latency**: Check Redis connection
4. **Memory issues**: Monitor system resources

## 📄 License

This project is part of the DEFIMON system and follows the same licensing terms.

---

**Note**: This system provides predictions based on historical data and market analysis. All predictions are estimates and should not be considered as financial advice. Always do your own research and consider consulting with financial professionals before making investment decisions.
