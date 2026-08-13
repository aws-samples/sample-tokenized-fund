import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, QueryCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);
const TABLE_NAME = process.env.TABLE_NAME || 'AssetData';

/**
 * Lambda handler for retrieving the latest proof of reserves record
 * Requirements: 4.1, 4.2, 4.3, 4.4
 */
export async function handler(event: APIGatewayProxyEvent): Promise<APIGatewayProxyResult> {
    try {
        // Query DynamoDB for latest proof of reserves record (Requirement 4.1)
        // Using descending sort on timestamp and limit 1 to get the most recent record
        const result = await docClient.send(new QueryCommand({
            TableName: TABLE_NAME,
            KeyConditionExpression: 'recordType = :recordType',
            ExpressionAttributeValues: {
                ':recordType': 'PROOF_OF_RESERVES'
            },
            ScanIndexForward: false, // Descending sort on timestamp
            Limit: 1
        }));

        // Check if any records exist (Requirement 4.3)
        if (!result.Items || result.Items.length === 0) {
            return {
                statusCode: 404,
                headers: {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                body: JSON.stringify({
                    error: 'No proof of reserves records found',
                    code: 'NOT_FOUND'
                })
            };
        }

        const latestRecord = result.Items[0];

        // Return success response with collateralUsd and timestamp (Requirements 4.2, 4.4)
        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            body: JSON.stringify({
                collateralUsd: latestRecord.collateralUsd,
                timestamp: latestRecord.timestamp
            })
        };

    } catch (error) {
        console.error('Error retrieving proof of reserves:', error);

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
