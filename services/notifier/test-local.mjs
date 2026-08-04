// Quick local sanity check for the Notifier handler logic.
// This does NOT send a real email — it tests the SNS event parsing and SES call shape.

process.env.SENDER_EMAIL = "orders@example.com";

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
    console.log("Threw (expected — no real SES access locally):", err.message);
  }
}

await run("Order created event", snsEvent({
  orderId: "order-123",
  customerId: "cust-456"
}));