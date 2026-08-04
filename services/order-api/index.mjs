import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { randomUUID } from "crypto";

const sqs = new SQSClient({});
const QUEUE_URL = process.env.ORDER_QUEUE_URL;

export const handler = async (event) => {
  let body;
  try {
    body = JSON.parse(event.body || "{}");
  } catch {
    return response(400, { error: "Invalid JSON in request body" });
  }

  // Basic validation
  if (!body.customerId || !body.items || !Array.isArray(body.items) || body.items.length === 0) {
    return response(400, {
      error: "Request must include customerId and a non-empty items array"
    });
  }

  // Idempotency key: use the client-supplied one, or generate one
  const idempotencyKey = body.idempotencyKey || randomUUID();
  const orderId = randomUUID();

  const message = {
    orderId,
    idempotencyKey,
    customerId: body.customerId,
    items: body.items,
    simulateFailure: body.simulateFailure === true, // demo hook for Phase 3 failure testing
    createdAt: new Date().toISOString()
  };

  try {
    await sqs.send(new SendMessageCommand({
      QueueUrl: QUEUE_URL,
      MessageBody: JSON.stringify(message)
    }));
  } catch (err) {
    console.error(JSON.stringify({ stage: "order-api", error: err.message, orderId }));
    return response(502, { error: "Failed to queue order, please try again" });
  }

  console.log(JSON.stringify({ stage: "order-api", orderId, idempotencyKey, status: "accepted" }));

  return response(202, { orderId, status: "accepted" });
};

function response(statusCode, body) {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body)
  };
}