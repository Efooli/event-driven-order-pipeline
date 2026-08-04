import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, UpdateCommand } from "@aws-sdk/lib-dynamodb";

const ddbClient = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(ddbClient);

const TABLE_NAME = process.env.ORDERS_TABLE_NAME;
const LOW_STOCK_THRESHOLD = 5;

export const handler = async (event) => {
  for (const record of event.Records) {
    await processRecord(record);
  }
};

async function processRecord(record) {
  const snsMessage = JSON.parse(record.Sns.Message);
  const { orderId, items } = snsMessage;

  console.log(JSON.stringify({ stage: "inventory-updater", orderId, status: "processing" }));

  try {
    // Mark the order's inventory as reserved. In a real system this would
    // decrement per-SKU stock in a separate inventory table; here we keep
    // it simple and record the reservation status on the order record itself.
    await ddb.send(new UpdateCommand({
      TableName: TABLE_NAME,
      Key: { orderId },
      UpdateExpression: "SET inventoryStatus = :status, inventoryUpdatedAt = :time",
      ExpressionAttributeValues: {
        ":status": "reserved",
        ":time": new Date().toISOString()
      },
      ConditionExpression: "attribute_exists(orderId)"
    }));

    console.log(JSON.stringify({ stage: "inventory-updater", orderId, status: "reserved" }));

    // Demo stock-threshold check (mocked — a real system would check actual per-SKU counts)
    const mockRemainingStock = Math.floor(Math.random() * 10);
    if (mockRemainingStock < LOW_STOCK_THRESHOLD) {
      console.warn(JSON.stringify({
        stage: "inventory-updater",
        orderId,
        status: "low_stock_warning",
        remainingStock: mockRemainingStock
      }));
    }
  } catch (err) {
    console.error(JSON.stringify({ stage: "inventory-updater", orderId, error: err.message }));
    throw err;
  }
}