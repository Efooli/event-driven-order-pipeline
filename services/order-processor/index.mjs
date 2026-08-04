import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand } from "@aws-sdk/lib-dynamodb";
import { SNSClient, PublishCommand } from "@aws-sdk/client-sns";

const ddbClient = new DynamoDBClient({});
const ddb = DynamoDBDocumentClient.from(ddbClient);
const sns = new SNSClient({});

const TABLE_NAME = process.env.ORDERS_TABLE_NAME;
const TOPIC_ARN = process.env.ORDER_EVENTS_TOPIC_ARN;

export const handler = async (event) => {
  // SQS can batch multiple records into one invocation
  for (const record of event.Records) {
    await processRecord(record);
  }
};

async function processRecord(record) {
  const message = JSON.parse(record.body);
  const { orderId, idempotencyKey, customerId, items, simulateFailure } = message;

  console.log(JSON.stringify({ stage: "order-processor", orderId, idempotencyKey, status: "received" }));

  // Demo hook: lets us trigger the DLQ path on demand for the portfolio demo
  if (simulateFailure) {
    console.error(JSON.stringify({ stage: "order-processor", orderId, status: "simulated_failure" }));
    throw new Error("Simulated failure for demo purposes");
  }

  try {
    // Conditional write: reject if this idempotency key already exists (ADR 3)
    await ddb.send(new PutCommand({
      TableName: TABLE_NAME,
      Item: {
        orderId,
        idempotencyKey,
        customerId,
        items,
        status: "created",
        createdAt: new Date().toISOString()
      },
      ConditionExpression: "attribute_not_exists(orderId)"
    }));
  } catch (err) {
    if (err.name === "ConditionalCheckFailedException") {
      console.log(JSON.stringify({ stage: "order-processor", orderId, status: "duplicate_ignored" }));
      return; // Already processed, don't retry, don't republish
    }
    console.error(JSON.stringify({ stage: "order-processor", orderId, error: err.message }));
    throw err; // Let SQS retry transient failures
  }

  // Publish event for downstream consumers (Notifier, Inventory Updater)
  await sns.send(new PublishCommand({
    TopicArn: TOPIC_ARN,
    Message: JSON.stringify({ orderId, customerId, items }),
    MessageAttributes: {
      eventType: { DataType: "String", StringValue: "OrderCreated" }
    }
  }));

  console.log(JSON.stringify({ stage: "order-processor", orderId, status: "persisted_and_published" }));
}