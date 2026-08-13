import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand, QueryCommand } from '@aws-sdk/lib-dynamodb';
import { validatePrice } from '../utils/validation';
import { StockPriceRecord, StockPriceResponse } from '../types';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || 'AssetData';
const FINNHUB_API_KEY = process.env.STOCK_API_KEY || '';
const ALPHA_VANTAGE_API_KEY = process.env.ALPHA_VANTAGE_API_KEY || '';
const STOCK_SYMBOL = process.env.STOCK_SYMBOL || 'SPY';

// API base URLs
const FINNHUB_API_URL = 'https://finnhub.io/api/v1';
const ALPHA_VANTAGE_API_URL = 'https://www.alphavantage.co/query';

interface FinnhubQuoteResponse {
    c: number;  // Current price
    d: number;  // Change
    dp: number; // Percent change
    h: number;  // High price of the day
    l: number;  // Low price of the day
    o: number;  // Open price of the day
    pc: number; // Previous close price
    t: number;  // Timestamp
}

interface AlphaVantageQuoteResponse {
    'Global Quote': {
        '01. symbol': string;
        '02. open': string;
        '03. high': string;
        '04. low': string;
        '05. price': string;
        '06. volume': string;
        '07. latest trading day': string;
        '08. previous close': string;
        '09. change': string;
        '10. change percent': string;
    };
}

interface PriceResult {
    price: number;
    source: string;
    timestamp: number;
}

/**
 * Fetches stock price from Finnhub API
 */
async function fetchFromFinnhub(symbol: string): Promise<PriceResult | null> {
    if (!FINNHUB_API_KEY) {
        console.log('Finnhub API key not configured, skipping');
        return null;
    }

    try {
        const url = `${FINNHUB_API_URL}/quote?symbol=${symbol}&token=${FINNHUB_API_KEY}`;
        const response = await fetch(url);

        if (!response.ok) {
            console.error(`Finnhub API error: ${response.status} ${response.statusText}`);
            return null;
        }

        const data = await response.json() as FinnhubQuoteResponse;

        // Finnhub returns 0 for invalid symbols or when market is closed with no data
        if (data.c === 0 && data.pc === 0) {
            console.error(`Finnhub: No price data available for symbol: ${symbol}`);
            return null;
        }

        return {
            price: data.c,
            source: 'finnhub',
            timestamp: data.t || Math.floor(Date.now() / 1000)
        };
    } catch (error) {
        console.error('Finnhub fetch error:', error);
        return null;
    }
}


/**
 * Fetches stock price from Alpha Vantage API
 */
async function fetchFromAlphaVantage(symbol: string): Promise<PriceResult | null> {
    if (!ALPHA_VANTAGE_API_KEY) {
        console.log('Alpha Vantage API key not configured, skipping');
        return null;
    }

    try {
        const url = `${ALPHA_VANTAGE_API_URL}?function=GLOBAL_QUOTE&symbol=${symbol}&apikey=${ALPHA_VANTAGE_API_KEY}`;
        const response = await fetch(url);

        if (!response.ok) {
            console.error(`Alpha Vantage API error: ${response.status} ${response.statusText}`);
            return null;
        }

        const data = await response.json() as AlphaVantageQuoteResponse;

        // Check if we got valid data
        if (!data['Global Quote'] || !data['Global Quote']['05. price']) {
            console.error('Alpha Vantage: No price data in response');
            return null;
        }

        const price = parseFloat(data['Global Quote']['05. price']);
        if (isNaN(price) || price <= 0) {
            console.error('Alpha Vantage: Invalid price value:', data['Global Quote']['05. price']);
            return null;
        }

        return {
            price,
            source: 'alphavantage',
            timestamp: Math.floor(Date.now() / 1000)
        };
    } catch (error) {
        console.error('Alpha Vantage fetch error:', error);
        return null;
    }
}

/**
 * Calculates the mathematical average of prices from multiple sources
 */
function calculateAveragePrice(results: PriceResult[]): { averagePrice: number; sources: string[]; prices: number[] } {
    if (results.length === 0) {
        throw new Error('No valid prices to average');
    }

    const prices = results.map(r => r.price);
    const sources = results.map(r => r.source);
    const sum = prices.reduce((acc, price) => acc + price, 0);
    const averagePrice = sum / prices.length;

    return {
        averagePrice: Math.round(averagePrice * 100) / 100, // Round to 2 decimal places
        sources,
        prices
    };
}

/**
 * Stores stock price in DynamoDB
 */
async function storeStockPrice(symbol: string, price: number, timestamp: string, sources: string[]): Promise<void> {
    const record: StockPriceRecord = {
        recordType: `STOCK_${symbol}`,
        timestamp,
        price,
        symbol
    };

    // Add sources as additional metadata
    await docClient.send(new PutCommand({
        TableName: TABLE_NAME,
        Item: {
            ...record,
            sources
        }
    }));
}

/**
 * Retrieves latest stock price from DynamoDB
 */
async function getLatestStoredPrice(symbol: string): Promise<StockPriceRecord | null> {
    const result = await docClient.send(new QueryCommand({
        TableName: TABLE_NAME,
        KeyConditionExpression: 'recordType = :recordType',
        ExpressionAttributeValues: {
            ':recordType': `STOCK_${symbol}`
        },
        ScanIndexForward: false,
        Limit: 1
    }));

    if (!result.Items || result.Items.length === 0) {
        return null;
    }

    return result.Items[0] as StockPriceRecord;
}


/**
 * Lambda handler for fetching and returning stock price
 * - Fetches stock price from multiple APIs (Finnhub, Alpha Vantage)
 * - Calculates mathematical average of all successful responses
 * - Stores averaged price in DynamoDB with asset type "STOCK_SPY"
 * - Exposes latest price via API Gateway
 * - Validates price is positive before storing
 * - Returns error response on API failure
 * - Falls back to single API if one fails
 * - Supports configurable stock symbol via environment variable
 */
export async function handler(_event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
    const headers = {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
    };

    try {
        // Check if at least one API key is configured
        if (!FINNHUB_API_KEY && !ALPHA_VANTAGE_API_KEY) {
            console.error('No stock API keys configured');
            return {
                statusCode: 500,
                headers,
                body: JSON.stringify({
                    error: 'Stock API not configured',
                    code: 'CONFIG_ERROR'
                })
            };
        }

        // Fetch from both APIs in parallel
        const [finnhubResult, alphaVantageResult] = await Promise.all([
            fetchFromFinnhub(STOCK_SYMBOL),
            fetchFromAlphaVantage(STOCK_SYMBOL)
        ]);

        // Collect successful results
        const validResults: PriceResult[] = [];
        if (finnhubResult) validResults.push(finnhubResult);
        if (alphaVantageResult) validResults.push(alphaVantageResult);

        // Check if we got at least one valid price
        if (validResults.length === 0) {
            throw new Error('All stock API requests failed');
        }

        // Calculate average price
        const { averagePrice, sources, prices } = calculateAveragePrice(validResults);

        // Validate averaged price is positive
        const validation = validatePrice(averagePrice);
        if (!validation.isValid) {
            console.error('Invalid averaged price:', averagePrice);
            return {
                statusCode: 500,
                headers,
                body: JSON.stringify({
                    error: validation.error || 'Invalid price from stock APIs',
                    code: 'VALIDATION_ERROR'
                })
            };
        }

        // Create ISO timestamp for storage
        const timestamp = new Date().toISOString();

        // Store in DynamoDB
        await storeStockPrice(STOCK_SYMBOL, averagePrice, timestamp, sources);

        // Build response with price details
        const response: StockPriceResponse & {
            sources: string[];
            individualPrices: number[];
            priceCount: number;
        } = {
            price: averagePrice,
            timestamp,
            symbol: STOCK_SYMBOL,
            sources,
            individualPrices: prices,
            priceCount: validResults.length
        };

        return {
            statusCode: 200,
            headers,
            body: JSON.stringify(response)
        };

    } catch (error) {
        console.error('Error fetching stock price:', error);

        // Try to return cached price if available
        try {
            const cachedPrice = await getLatestStoredPrice(STOCK_SYMBOL);
            if (cachedPrice) {
                console.log('Returning cached price due to API error');
                const response: StockPriceResponse = {
                    price: cachedPrice.price,
                    timestamp: cachedPrice.timestamp,
                    symbol: cachedPrice.symbol
                };

                return {
                    statusCode: 200,
                    headers,
                    body: JSON.stringify({
                        ...response,
                        cached: true,
                        warning: 'Using cached price due to API error'
                    })
                };
            }
        } catch (cacheError) {
            console.error('Error retrieving cached price:', cacheError);
        }

        return {
            statusCode: 500,
            headers,
            body: JSON.stringify({
                error: error instanceof Error ? error.message : 'Failed to fetch stock price',
                code: 'API_ERROR'
            })
        };
    }
}
