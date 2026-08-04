// Quick local sanity check for the Order API handler logic.
// This does NOT call real AWS — it's just testing validation and response shape.

process.env.ORDER_QUEUE_URL = "https://fake-queue-url-for-local-test";

const { handler } = await import("./index.mjs");

async function run(label, event) {
  console.log(`\n--- ${label} ---`);
  try {
    const result = await handler(event);
    console.log(result);
  } catch (err) {
    console.log("Threw (expected if no real AWS creds/queue):", err.message);
  }
}

// Test 1: missing body entirely
await run("Missing body", {});

// Test 2: invalid JSON
await run("Invalid JSON", { body: "{not valid json" });

// Test 3: missing required fields
await run("Missing customerId", { body: JSON.stringify({ items: [{ sku: "ABC", qty: 1 }] }) });

// Test 4: valid request (will attempt a real SQS call and fail — that's expected locally)
await run("Valid request", {
  body: JSON.stringify({
    customerId: "cust-123",
    items: [{ sku: "ABC", qty: 2 }]
  })
});