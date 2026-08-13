import { APIGatewayProxyEvent } from 'aws-lambda';

// Store original env
const originalEnv = process.env;

// Mock fetch globally
const mockFetch = jest.fn();
global.fetch = mockFetch;

// Mock DynamoDB
const mockSend = jest.fn();
jest.mock('@aws-sdk/client-dynamodb', () => ({
    DynamoDBClient: jest.fn(() => ({}))
}));
jest.mock('@aws-sdk/lib-dynamodb', () => ({
    DynamoDBDocumentClient: {
        from: jest.fn(() => ({ send: mockSend }))
    },
    PutCommand: jest.fn((params) => ({ type: 'Put', params })),
    QueryCommand: jest.fn((params) => ({ type: 'Query', params }))
}));

const createMockEvent = (): APIGatewayProxyEvent => ({
    body: null,
    headers: {},
    multiValueHeaders: {},
    httpMethod: 'GET',
    isBase64Encoded: false,
    path: '/stock-price/latest',
    pathParameters: null,
    queryStringParameters: null,
    multiValueQueryStringParameters: null,
    stageVariables: null,
    requestContext: {} as any,
    resource: ''
});

describe('getStockPrice handler - dual API averaging', () => {
    let handler: typeof import('./getStockPrice').handler;

    const mockEnv = {
        TABLE_NAME: 'TestAssetData',
        STOCK_API_KEY: 'finnhub-test-key',
        ALPHA_VANTAGE_API_KEY: 'alphavantage-test-key',
        STOCK_SYMBOL: 'SPY'
    };

    beforeAll(() => {
        process.env = { ...originalEnv, ...mockEnv };
    });

    beforeEach(async () => {
        jest.clearAllMocks();
        jest.resetModules();
        process.env = { ...originalEnv, ...mockEnv };
        const module = await import('./getStockPrice');
        handler = module.handler;
    });

    afterAll(() => {
        process.env = originalEnv;
    });


    /**
     * Test: Both APIs return prices - should average them
     */
    it('should average prices from both Finnhub and Alpha Vantage', async () => {
        const finnhubPrice = 180.00;
        const alphaVantagePrice = 182.00;
        const expectedAverage = 181.00;

        // Mock Finnhub response
        mockFetch.mockResolvedValueOnce({
            ok: true,
            json: async () => ({
                c: finnhubPrice,
                d: 2.5,
                dp: 1.37,
                h: 186.00,
                l: 183.00,
                o: 184.00,
                pc: 183.00,
                t: Math.floor(Date.now() / 1000)
            })
        });

        // Mock Alpha Vantage response
        mockFetch.mockResolvedValueOnce({
            ok: true,
            json: async () => ({
                'Global Quote': {
                    '01. symbol': 'SPY',
                    '05. price': alphaVantagePrice.toString()
                }
            })
        });

        // Mock DynamoDB put success
        mockSend.mockResolvedValueOnce({});

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(200);

        const body = JSON.parse(result.body);
        expect(body.price).toBe(expectedAverage);
        expect(body.sources).toContain('finnhub');
        expect(body.sources).toContain('alphavantage');
        expect(body.individualPrices).toEqual([finnhubPrice, alphaVantagePrice]);
        expect(body.priceCount).toBe(2);
    });

    /**
     * Test: Only Finnhub succeeds - should use single price
     */
    it('should use single price when only Finnhub succeeds', async () => {
        const finnhubPrice = 185.50;

        // Mock Finnhub success
        mockFetch.mockResolvedValueOnce({
            ok: true,
            json: async () => ({
                c: finnhubPrice,
                pc: 183.00,
                t: Math.floor(Date.now() / 1000)
            })
        });

        // Mock Alpha Vantage failure
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 500,
            statusText: 'Internal Server Error'
        });

        mockSend.mockResolvedValueOnce({});

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(200);

        const body = JSON.parse(result.body);
        expect(body.price).toBe(finnhubPrice);
        expect(body.sources).toEqual(['finnhub']);
        expect(body.priceCount).toBe(1);
    });

    /**
     * Test: Only Alpha Vantage succeeds - should use single price
     */
    it('should use single price when only Alpha Vantage succeeds', async () => {
        const alphaVantagePrice = 184.25;

        // Mock Finnhub failure
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 401,
            statusText: 'Unauthorized'
        });

        // Mock Alpha Vantage success
        mockFetch.mockResolvedValueOnce({
            ok: true,
            json: async () => ({
                'Global Quote': {
                    '01. symbol': 'SPY',
                    '05. price': alphaVantagePrice.toString()
                }
            })
        });

        mockSend.mockResolvedValueOnce({});

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(200);

        const body = JSON.parse(result.body);
        expect(body.price).toBe(alphaVantagePrice);
        expect(body.sources).toEqual(['alphavantage']);
        expect(body.priceCount).toBe(1);
    });

    /**
     * Test: Both APIs fail - should return cached or error
     */
    it('should return error when both APIs fail and no cache', async () => {
        // Mock both APIs failing
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 500,
            statusText: 'Internal Server Error'
        });
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 500,
            statusText: 'Internal Server Error'
        });

        // Mock no cached data
        mockSend.mockResolvedValueOnce({ Items: [] });

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(500);

        const body = JSON.parse(result.body);
        expect(body.error).toContain('All stock API requests failed');
        expect(body.code).toBe('API_ERROR');
    });

    /**
     * Test: Both APIs fail but cache exists - should return cached
     */
    it('should return cached price when both APIs fail', async () => {
        const cachedPrice = 179.00;

        // Mock both APIs failing
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 500,
            statusText: 'Error'
        });
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 500,
            statusText: 'Error'
        });

        // Mock cached data exists
        mockSend.mockResolvedValueOnce({
            Items: [{
                recordType: 'STOCK_SPY',
                timestamp: new Date().toISOString(),
                price: cachedPrice,
                symbol: 'SPY'
            }]
        });

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(200);

        const body = JSON.parse(result.body);
        expect(body.price).toBe(cachedPrice);
        expect(body.cached).toBe(true);
    });
});


describe('getStockPrice handler - single API configured', () => {
    let handler: typeof import('./getStockPrice').handler;

    beforeEach(async () => {
        jest.clearAllMocks();
        jest.resetModules();
    });

    afterAll(() => {
        process.env = originalEnv;
    });

    it('should work with only Finnhub API key configured', async () => {
        process.env = {
            ...originalEnv,
            TABLE_NAME: 'TestAssetData',
            STOCK_API_KEY: 'finnhub-key',
            ALPHA_VANTAGE_API_KEY: '',
            STOCK_SYMBOL: 'SPY'
        };

        const module = await import('./getStockPrice');
        handler = module.handler;

        const finnhubPrice = 186.00;

        mockFetch.mockResolvedValueOnce({
            ok: true,
            json: async () => ({
                c: finnhubPrice,
                pc: 184.00,
                t: Math.floor(Date.now() / 1000)
            })
        });

        mockSend.mockResolvedValueOnce({});

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(200);
        const body = JSON.parse(result.body);
        expect(body.price).toBe(finnhubPrice);
        expect(body.sources).toEqual(['finnhub']);
    });

    it('should return config error when no API keys configured', async () => {
        process.env = {
            ...originalEnv,
            TABLE_NAME: 'TestAssetData',
            STOCK_API_KEY: '',
            ALPHA_VANTAGE_API_KEY: '',
            STOCK_SYMBOL: 'SPY'
        };

        const module = await import('./getStockPrice');
        handler = module.handler;

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(500);
        const body = JSON.parse(result.body);
        expect(body.error).toBe('Stock API not configured');
        expect(body.code).toBe('CONFIG_ERROR');
    });
});

describe('getStockPrice handler - price validation', () => {
    let handler: typeof import('./getStockPrice').handler;

    const mockEnv = {
        TABLE_NAME: 'TestAssetData',
        STOCK_API_KEY: 'finnhub-key',
        ALPHA_VANTAGE_API_KEY: 'alphavantage-key',
        STOCK_SYMBOL: 'SPY'
    };

    beforeEach(async () => {
        jest.clearAllMocks();
        jest.resetModules();
        process.env = { ...originalEnv, ...mockEnv };
        const module = await import('./getStockPrice');
        handler = module.handler;
    });

    afterAll(() => {
        process.env = originalEnv;
    });

    it('should reject negative averaged price', async () => {
        // Mock Finnhub with negative price
        mockFetch.mockResolvedValueOnce({
            ok: true,
            json: async () => ({
                c: -10.00,
                pc: 100,
                t: Math.floor(Date.now() / 1000)
            })
        });

        // Mock Alpha Vantage failure so only negative price is used
        mockFetch.mockResolvedValueOnce({
            ok: false,
            status: 500,
            statusText: 'Error'
        });

        const result = await handler(createMockEvent());

        expect(result.statusCode).toBe(500);
        const body = JSON.parse(result.body);
        expect(body.code).toBe('VALIDATION_ERROR');
    });
});
