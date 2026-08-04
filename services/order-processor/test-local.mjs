// Quick local sanity check for the Order Processor handler logic.
// This does NOT call real AWS — it tests the demo failure hook and event shape handling.

process.env.ORDERS_TABLE_NAME = "fake-table-for-local-test";
process.env.ORDER_EVENTS_TOPIC_ARN = "arn:aws:sns:us-east-1:000000000000:fake-topic";

const { handler } = await import("./index.mjs");

function sqsEvent(body) {
  return { Records: [{ body: JSON.stringify(body) }] };
}

async function run(label, event) {
  console.log(`\n--- ${label} ---`);
  try {
    await handler(event);
    console.log("Handled without throwing");
  } catch (err) {
    console.log("Threw:", err.message);
  }
}

// Test 1: simulateFailure flag should throw immediately (before any AWS call)
await run("Simulated failure", sqsEvent({
  orderId: "order-1",
  idempotencyKey: "idem-1",
  customerId: "cust-1",
  items: [{ sku: "ABC", qty: 1 }],
  simulateFailure: true
}));

// Test 2: normal order — will attempt a real DynamoDB call and fail (fake table) — that's expected
await run("Normal order (fake AWS target)", sqsEvent({
  orderId: "order-2",
  idempotencyKey: "idem-2",
  customerId: "cust-2",
  items: [{ sku: "XYZ", qty: 3 }],
  simulateFailure: false
}));