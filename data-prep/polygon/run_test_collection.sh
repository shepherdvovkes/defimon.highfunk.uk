#!/bin/bash

echo "🧪 Running Polygon Data Collection Test"
echo "======================================="

# Check if we're in the right directory
if [ ! -f "test_data_collection.py" ]; then
    echo "❌ Error: test_data_collection.py not found"
    exit 1
fi

echo "✅ Found test script"

# Run test with automatic confirmation
echo "y" | python3 test_data_collection.py

echo ""
echo "🎉 Test completed!"
echo "📊 Check the results above"
