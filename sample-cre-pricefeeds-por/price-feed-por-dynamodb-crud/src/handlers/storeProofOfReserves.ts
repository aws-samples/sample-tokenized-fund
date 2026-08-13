import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, PutCommand } from '@aws-sdk/lib-dynamodb';
import { validateCollateral } from '../utils/validation';
import { ProofOfReservesRecord } from '../types';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || 'AssetData';

/**
 * Lambda handler for storing proof of reserves records
 * Requirements: 3.1, 3.2, 3.3, 3.4
 */
export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
    try {
        // Parse request body
        if (!event.body) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'Request body is required',
                    code: 'MISSING_BODY'
                })
            };
        }

        let requestBody: any;
        try {
            requestBody = JSON.parse(event.body);
        } catch (error) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'Invalid JSON in request body',
                    code: 'INVALID_JSON'
                })
            };
        }

        // Validate collateral amount (Requirement 3.2)
        const validation = validateCollateral(requestBody.collateralUsd);
        if (!validation.isValid) {
            return {
                statusCode: 400,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: validation.error,
                    code: 'VALIDATION_ERROR'
                })
            };
        }

        // Create timestamp
        const timestamp = new Date().toISOString();

        // Create proof of reserves record
        const record: ProofOfReservesRecord = {
            recordType: 'PROOF_OF_RESERVES',
            timestamp,
            collateralUsd: requestBody.collateralUsd
        };

        // Store in DynamoDB (Requirement 3.1)
        await docClient.send(new PutCommand({
            TableName: TABLE_NAME,
            Item: record
        }));

        // Return success response (Requirement 3.4)
        return {
            statusCode: 201,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                success: true,
                timestamp
            })
        };

    } catch (error) {
        console.error('Error storing proof of reserves:', error);

        // Return server error (Requirement 3.3)
        return {
            statusCode: 500,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                error: 'Internal server error',
                code: 'INTERNAL_ERROR'
            })
        };
    }
}
