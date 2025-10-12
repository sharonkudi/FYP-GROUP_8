const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Gmail transporter (gunakan app password Gmail)
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: "syahshaheezam@gmail.com", // tukar ke email mu
    pass: "12345678",    // app password dari Gmail
  },
});

// Trigger bila ada admin baru di Firestore
exports.sendWelcomeEmail = functions.firestore
  .document("admins/{uid}")
  .onCreate(async (snap, context) => {
    const data = snap.data();

    const mailOptions = {
      from: "BaskuBN <syahshaheezam@gmail.com>",
      to: data.email,
      subject: "Welcome to BaskuBN",
      text: `Hi ${data.name}, you have registered as a new admin user for BaskuBN. We’re glad to have you onboard.`,
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log("✅ Welcome email sent to", data.email);
    } catch (error) {
      console.error("❌ Error sending email:", error);
    }
  });
