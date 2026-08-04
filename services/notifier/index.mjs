import { SESv2Client, SendEmailCommand } from "@aws-sdk/client-sesv2";

const ses = new SESv2Client({});
const SENDER_EMAIL = process.env.SENDER_EMAIL || "orders@example.com";

export const handler = async (event) => {
  for (const record of event.Records) {
    await processRecord(record);
  }
};

async function processRecord(record) {
  const snsMessage = JSON.parse(record.Sns.Message);
  const { orderId, customerId } = snsMessage;

  console.log(JSON.stringify({ stage: "notifier", orderId, customerId, status: "sending" }));

  try {
    await ses.send(new SendEmailCommand({
      FromEmailAddress: SENDER_EMAIL,
      Destination: { ToAddresses: [`${customerId}@example.com`] }, // placeholder for demo purposes
      Content: {
        Simple: {
          Subject: { Data: `Order Confirmation - ${orderId}` },
          Body: {
            Text: { Data: `Thanks for your order! Your order ID is ${orderId}.` }
          }
        }
      }
    }));
    console.log(JSON.stringify({ stage: "notifier", orderId, status: "sent" }));
  } catch (err) {
    console.error(JSON.stringify({ stage: "notifier", orderId, error: err.message }));
    throw err; // let SNS/Lambda retry policy handle it
  }
}