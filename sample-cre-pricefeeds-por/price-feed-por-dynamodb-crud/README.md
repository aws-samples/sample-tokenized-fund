# Asset Price Service (AWS Lambda)

Serverless REST API for stock prices and proof of reserves data using Lambda, API Gateway, and DynamoDB.

## Deployment

```bash
cd sample-cre-pricefeeds-por/price-feed-por-dynamodb-crud

# Set API keys (at least one required for live prices)
export FINNHUB_API_KEY=<your-key>
export ALPHA_VANTAGE_API_KEY=<your-key>

./deploy.sh
./verify-deployment.sh
```

Without API keys, the stock price endpoint returns simulated data only.

## API Endpoints

All endpoints require `x-api-key` header.

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/stock-price/latest` | Get latest stock price (from Finnhub/Alpha Vantage) |
| POST | `/asset-price` | Store asset price |
| GET | `/asset-price/latest` | Get latest stored price |
| POST | `/proof-of-reserves` | Store proof of reserves |
| GET | `/proof-of-reserves/latest` | Get latest reserves |
| POST | `/simulate` | Generate test data |

## Testing

```bash
# After deployment, test the API
source ./setup-env.sh
./test-api.sh

# Or manually
curl -H "x-api-key: $API_KEY" "${API_URL}stock-price/latest"
```

## Monitoring

```bash
npm run logs                          # All function logs
sam logs -n StoreAssetPriceFunction --stack-name asset-price-service --tail
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| API returns 403 | Check `x-api-key` header; run `./verify-deployment.sh` to get current key |
| Lambda timeout | Check CloudWatch logs (`npm run logs`); verify DynamoDB permissions |
| No data returned | Use `/simulate` to generate test data, or POST prices first |
| Deployment fails | Verify AWS credentials and IAM permissions for CF/Lambda/APIGW/DDB |

## Cleanup

```bash
sam delete --stack-name asset-price-service
```

## Cost

Within AWS Free Tier for typical dev usage ($0/month). Beyond free tier: ~$1-5/month.

## License

MIT
