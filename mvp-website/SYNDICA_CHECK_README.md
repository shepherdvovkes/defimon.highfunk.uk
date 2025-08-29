# Syndica API Credential Checker

A comprehensive web interface for testing and validating Syndica API credentials and connection status.

## Features

### 🔐 Credential Management
- Pre-filled API key and endpoint URL
- Editable credential fields
- One-click copy functionality for credentials
- Secure credential handling

### 🔍 Connection Testing
- Real-time connection status testing
- Multiple API method validation
- Response time measurement
- Detailed error reporting

### 📊 Rate Limit Information
- Complete rate limit table from official Syndica documentation
- Standard Mode vs Scale Mode limits
- WebSocket connection limits
- Method-specific rate limits

### 🎨 Modern UI
- Beautiful gradient design with glass morphism effects
- Smooth animations using Framer Motion
- Responsive design for all devices
- Real-time status indicators

## Usage

1. **Access the Page**: Navigate to `/syndica-check` in your browser
2. **Review Credentials**: The page comes pre-filled with your Syndica API credentials
3. **Test Connection**: Click "Test Connection" to validate your API access
4. **View Results**: See detailed test results for various API methods
5. **Check Limits**: Review rate limits and WebSocket connection limits

## API Methods Tested

The page automatically tests the following Solana RPC methods:
- `getBlockHeight` - Get current block height
- `getSlot` - Get current slot
- `getRecentBlockhash` - Get recent blockhash
- `getVersion` - Get Solana version

## Rate Limits

Based on the [official Syndica documentation](https://docs.syndica.io/platform/resources/rate-limits), the page displays:

### HTTP API Limits
| Method | Standard Mode (RPS) | Scale Mode (RPS) |
|--------|-------------------|------------------|
| getBlock | 25 | 100 |
| getBlockTime | 40 | 120 |
| getBlocks | 35 | 100 |
| getMultipleAccounts | 25 | 75 |
| getSignaturesForAddress | 50 | 150 |
| getTokenAccountsByOwner | 35 | 200 |
| getTransaction | 20 | 60 |
| sendTransaction | 20 | 60 |

### WebSocket Limits
- **Max Active Connections**: 100 (Standard) / 300 (Scale)
- **Max Total Subscriptions**: 100 (Standard) / 600 (Scale)
- **Max Subscriptions per Connection**: 100 (Standard) / 600 (Scale)

## Technical Details

- **Framework**: Next.js 15 with TypeScript
- **Styling**: Tailwind CSS with custom gradients
- **Animations**: Framer Motion
- **API**: Direct HTTP requests to Syndica endpoints
- **Error Handling**: Comprehensive error catching and display

## Security Notes

- API credentials are stored in client-side state only
- No credentials are sent to any server except Syndica
- All requests are made directly from the browser
- No credential logging or storage

## Deployment

This page is part of the main DEFIMON MVP website and will be deployed to Google Cloud Platform along with the rest of the application.

## Troubleshooting

### Common Issues

1. **CORS Errors**: Make sure you're using the correct Syndica endpoint URL
2. **Authentication Errors**: Verify your API key is correct and active
3. **Rate Limiting**: Check if you've exceeded your plan's rate limits
4. **Network Issues**: Ensure your network can reach Syndica's servers

### Error Messages

- **HTTP 401**: Invalid API key
- **HTTP 429**: Rate limit exceeded
- **HTTP 500**: Syndica server error
- **Network Error**: Connection timeout or DNS issues

## Links

- [Syndica Documentation](https://docs.syndica.io/platform/resources/rate-limits)
- [Solana RPC Methods](https://docs.solana.com/developing/clients/jsonrpc-api)
- [DEFIMON Project](https://defimon.highfunk.uk)
