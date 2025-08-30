#!/usr/bin/env python3
"""
Test script for ETH Price Predictions
Tests the 5 most popular ETH price questions
"""

import asyncio
import json
import sys
import os
from datetime import datetime

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models.eth_price_predictor import ETHPricePredictor

async def test_eth_price_predictions():
    """Test ETH price predictions for all timeframes"""
    print("🚀 Testing ETH Price Predictions")
    print("=" * 50)
    
    # Initialize predictor
    predictor = ETHPricePredictor()
    
    # Test current price
    print("\n📊 Getting current ETH price...")
    current_price = await predictor.get_current_eth_price()
    print(f"   Current ETH price: ${current_price:,.2f}")
    
    # Test historical data
    print("\n📈 Getting historical ETH data...")
    historical_data = await predictor.get_historical_eth_data(365)
    print(f"   Historical data points: {len(historical_data)}")
    
    if not historical_data.empty:
        print(f"   Date range: {historical_data['date'].min().date()} to {historical_data['date'].max().date()}")
        print(f"   Price range: ${historical_data['price'].min():,.2f} - ${historical_data['price'].max():,.2f}")
    
    # Test individual timeframe predictions
    timeframes = ["1m", "5m", "6m", "1y"]
    predictions = {}
    
    print("\n🔮 Testing individual timeframe predictions...")
    for timeframe in timeframes:
        print(f"\n   Testing {timeframe} prediction...")
        try:
            result = await predictor.predict_eth_price(timeframe)
            predictions[timeframe] = result
            
            print(f"   ✓ {timeframe} prediction completed")
            print(f"      Current: ${result['current_price']:,.2f}")
            print(f"      Predicted: ${result['prediction']['predicted_price']:,.2f}")
            print(f"      Expected return: {result['prediction']['expected_return_percent']:.1f}%")
            print(f"      Confidence: {result['prediction']['confidence']:.1%}")
            print(f"      Confidence interval: ${result['prediction']['confidence_interval']['lower']:,.2f} - ${result['prediction']['confidence_interval']['upper']:,.2f}")
            
        except Exception as e:
            print(f"   ✗ {timeframe} prediction failed: {e}")
    
    # Test all timeframes at once
    print("\n🎯 Testing all timeframes prediction...")
    try:
        all_predictions = await predictor.get_all_timeframe_predictions()
        print(f"   ✓ All predictions completed")
        print(f"   Current price: ${all_predictions['current_price']:,.2f}")
        
        for timeframe, pred in all_predictions['predictions'].items():
            print(f"   {timeframe}: ${pred['predicted_price']:,.2f} ({pred['expected_return_percent']:.1f}%)")
            
    except Exception as e:
        print(f"   ✗ All predictions failed: {e}")
    
    return predictions, all_predictions

async def answer_popular_questions():
    """Answer the 5 most popular ETH price questions"""
    print("\n" + "=" * 50)
    print("❓ ANSWERING THE 5 MOST POPULAR ETH PRICE QUESTIONS")
    print("=" * 50)
    
    predictor = ETHPricePredictor()
    
    # Question 1: What will be the ETH price in 1 month?
    print("\n1️⃣ Question: What will be the ETH price in 1 month?")
    try:
        result = await predictor.predict_eth_price("1m")
        current = result['current_price']
        predicted = result['prediction']['predicted_price']
        change = ((predicted - current) / current) * 100
        
        print(f"   Answer: ETH price is expected to be ${predicted:,.2f} in 1 month")
        print(f"   Change: {change:+.1f}% from current ${current:,.2f}")
        print(f"   Confidence: {result['prediction']['confidence']:.1%}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Question 2: What will be the ETH price in 5 months?
    print("\n2️⃣ Question: What will be the ETH price in 5 months?")
    try:
        result = await predictor.predict_eth_price("5m")
        current = result['current_price']
        predicted = result['prediction']['predicted_price']
        change = ((predicted - current) / current) * 100
        
        print(f"   Answer: ETH price is expected to be ${predicted:,.2f} in 5 months")
        print(f"   Change: {change:+.1f}% from current ${current:,.2f}")
        print(f"   Confidence: {result['prediction']['confidence']:.1%}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Question 3: What will be the ETH price in 6 months?
    print("\n3️⃣ Question: What will be the ETH price in 6 months?")
    try:
        result = await predictor.predict_eth_price("6m")
        current = result['current_price']
        predicted = result['prediction']['predicted_price']
        change = ((predicted - current) / current) * 100
        
        print(f"   Answer: ETH price is expected to be ${predicted:,.2f} in 6 months")
        print(f"   Change: {change:+.1f}% from current ${current:,.2f}")
        print(f"   Confidence: {result['prediction']['confidence']:.1%}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Question 4: What will be the ETH price in 1 year?
    print("\n4️⃣ Question: What will be the ETH price in 1 year?")
    try:
        result = await predictor.predict_eth_price("1y")
        current = result['current_price']
        predicted = result['prediction']['predicted_price']
        change = ((predicted - current) / current) * 100
        
        print(f"   Answer: ETH price is expected to be ${predicted:,.2f} in 1 year")
        print(f"   Change: {change:+.1f}% from current ${current:,.2f}")
        print(f"   Confidence: {result['prediction']['confidence']:.1%}")
    except Exception as e:
        print(f"   Error: {e}")
    
    # Question 5: What are the ETH price trends and predictions?
    print("\n5️⃣ Question: What are the ETH price trends and predictions?")
    try:
        all_predictions = await predictor.get_all_timeframe_predictions()
        current = all_predictions['current_price']
        
        # Calculate overall trend
        predictions = all_predictions['predictions']
        short_term = predictions['1m']['predicted_price']
        medium_term = predictions['6m']['predicted_price']
        long_term = predictions['1y']['predicted_price']
        
        overall_trend = "bullish" if long_term > current else "bearish"
        
        print(f"   Answer: ETH price trends show a {overall_trend} outlook:")
        print(f"   • Short-term (1 month): ${short_term:,.2f}")
        print(f"   • Medium-term (6 months): ${medium_term:,.2f}")
        print(f"   • Long-term (1 year): ${long_term:,.2f}")
        print(f"   • Current price: ${current:,.2f}")
        
        # Calculate confidence range
        confidences = [p['confidence'] for p in predictions.values()]
        print(f"   • Confidence range: {min(confidences):.1%} - {max(confidences):.1%}")
        
    except Exception as e:
        print(f"   Error: {e}")

async def generate_summary_report():
    """Generate a summary report of all predictions"""
    print("\n" + "=" * 50)
    print("📋 ETH PRICE PREDICTION SUMMARY REPORT")
    print("=" * 50)
    
    predictor = ETHPricePredictor()
    
    try:
        # Get current price
        current_price = await predictor.get_current_eth_price()
        
        # Get all predictions
        all_predictions = await predictor.get_all_timeframe_predictions()
        
        print(f"\n📊 Current ETH Price: ${current_price:,.2f}")
        print(f"📅 Report Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        
        print("\n🔮 Price Predictions:")
        print("-" * 40)
        
        predictions = all_predictions['predictions']
        for timeframe, pred in predictions.items():
            timeframe_name = {
                "1m": "1 Month",
                "5m": "5 Months", 
                "6m": "6 Months",
                "1y": "1 Year"
            }.get(timeframe, timeframe)
            
            predicted_price = pred['predicted_price']
            change_percent = ((predicted_price - current_price) / current_price) * 100
            confidence = pred['confidence']
            
            print(f"{timeframe_name:>10}: ${predicted_price:>10,.2f} ({change_percent:+6.1f}%) [{confidence:5.1%}]")
        
        print("\n📈 Key Insights:")
        print("-" * 40)
        
        # Calculate insights
        short_term = predictions['1m']['predicted_price']
        long_term = predictions['1y']['predicted_price']
        
        if long_term > current_price:
            print("• Overall trend: Bullish")
        else:
            print("• Overall trend: Bearish")
        
        if short_term > current_price:
            print("• Short-term outlook: Positive")
        else:
            print("• Short-term outlook: Negative")
        
        # Volatility analysis
        confidences = [p['confidence'] for p in predictions.values()]
        avg_confidence = sum(confidences) / len(confidences)
        
        if avg_confidence > 0.7:
            print("• Model confidence: High")
        elif avg_confidence > 0.5:
            print("• Model confidence: Medium")
        else:
            print("• Model confidence: Low")
        
        print(f"• Average confidence: {avg_confidence:.1%}")
        
        print(f"\n📊 Data Points Used: {all_predictions['summary']['data_points_used']}")
        
    except Exception as e:
        print(f"Error generating report: {e}")

async def main():
    """Main test function"""
    print("🚀 ETH Price Prediction Test Suite")
    print("Testing the 5 most popular ETH price questions")
    print("=" * 60)
    
    try:
        # Test basic functionality
        await test_eth_price_predictions()
        
        # Answer the 5 popular questions
        await answer_popular_questions()
        
        # Generate summary report
        await generate_summary_report()
        
        print("\n" + "=" * 60)
        print("✅ All tests completed successfully!")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit_code = asyncio.run(main())
    sys.exit(exit_code)
