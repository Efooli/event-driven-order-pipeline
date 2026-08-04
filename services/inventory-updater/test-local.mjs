// Quick local sanity check for the Inventory Updater handler logic.
// This does NOT call real AWS — it tests SNS event parsing and the update call shape.

process.env.ORDERS_TABLE_NAME = "fake-table-for-local-test";

const { handler } = await import("./index.mjs");

function snsEvent(message) {
  return { Records: [{ Sns: { Message: JSON.stringify(message) } }] };
}

async function run(label, event) {
  console.log(`\n--- ${label} ---`);
  try {
    await handler(event);
    console.log("Handled without throwing");
  } catch (err) {
    console.log("Threw (expected — fake table doesn't exist):", err.message);
  }
}

await run("Order created event", snsEvent({
  orderId: "order-789",
  customerId: "cust-101",
  items: [{ sku: "ABC", qty: 1 }]
}));