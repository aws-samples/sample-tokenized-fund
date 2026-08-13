export interface AssetPriceRecord {
    recordType: 'ASSET_PRICE';
    timestamp: string;
    price: number;
}

export interface ProofOfReservesRecord {
    recordType: 'PROOF_OF_RESERVES';
    timestamp: string;
    collateralUsd: number;
}

/**
 * Stock price record stored in DynamoDB
 * Requirements: 1.1, 1.2
 */
export interface StockPriceRecord {
    recordType: string; // e.g., 'STOCK_SPY'
    timestamp: string;
    price: number;
    symbol: string;
}

/**
 * Response format for stock price API endpoint
 * Requirements: 1.3
 */
export interface StockPriceResponse {
    price: number;
    timestamp: string;
    symbol: string;
}

export type DataRecord = AssetPriceRecord | ProofOfReservesRecord | StockPriceRecord;
