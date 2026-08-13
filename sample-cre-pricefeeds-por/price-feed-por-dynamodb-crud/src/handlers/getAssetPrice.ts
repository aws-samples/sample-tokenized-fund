import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || 'AssetData';

/**
 * Lambda handler for retrieving the latest asset price record
 * Requirements: 2.1, 2.2, 2.3, 2.4
 */
export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
    try {
        // Query DynamoDB for latest asset price record (Requirement 2.1)
        // Using descending sort on timestamp and limit 1 to get the most recent record
        const result = await docClient.send(new QueryCommand({
            TableName: TABLE_NAME,
            KeyConditionExpression: 'recordType = :recordType',
            ExpressionAttributeValues: {
                ':recordType': 'ASSET_PRICE'
            },
            ScanIndexForward: false, // Descending sort on timestamp
            Limit: 1
        }));

        // Check if any records exist (Requirement 2.3)
        if (!result.Items || result.Items.length === 0) {
            return {
                statusCode: 404,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'No asset price records found',
                    code: 'NOT_FOUND'
                })
            };
        }

        const latestRecord = result.Items[0];

        // Return success response with price and timestamp (Requirements 2.2, 2.4)
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                price: latestRecord.price,
                timestamp: latestRecord.timestamp
            })
        };

    } catch (error) {
        console.error('Error retrieving asset price:', error);

        // Return server error
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
