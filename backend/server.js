require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.post('/api/send-otp', async (req, res) => {
  const { email, otp } = req.body;
  
  if (!email || !otp) {
    return res.status(400).json({ error: 'Email and OTP are required' });
  }

  // Get API key from environment variable
  const brevoApiKey = process.env.BREVO_API_KEY;
  if (!brevoApiKey) {
    console.error('BREVO_API_KEY environment variable is not set');
    return res.status(500).json({ error: 'Server configuration error' });
  }

  const senderEmail = 'aakasltf06@gmail.com';
  const senderName = 'Ascent';
  
  const brevoUrl = 'https://api.brevo.com/v3/smtp/email';
  
  const headers = {
    'accept': 'application/json',
    'api-key': brevoApiKey,
    'content-type': 'application/json',
  };
  
  const data = {
    sender: {
      name: senderName,
      email: senderEmail,
    },
    to: [
      {
        email: email,
      }
    ],
    subject: 'Your Ascent Verification Code',
    htmlContent: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #e0e0e0; border-radius: 10px;">
        <h2 style="color: #6C63FF; text-align: center;">Ascent Authentication</h2>
        <p style="font-size: 16px; color: #333;">Hello,</p>
        <p style="font-size: 16px; color: #333;">Your one-time password (OTP) for accessing Ascent is:</p>
        <div style="text-align: center; margin: 30px 0;">
          <span style="display: inline-block; padding: 15px 30px; font-size: 24px; font-weight: bold; color: #fff; background-color: #6C63FF; border-radius: 8px; letter-spacing: 5px;">${otp}</span>
        </div>
        <p style="font-size: 14px; color: #666; text-align: center;">This code will expire in 10 minutes. Please do not share it with anyone.</p>
      </div>
    `,
  };

  try {
    const response = await axios.post(brevoUrl, data, { headers });
    res.status(200).json({ success: true, message: 'OTP sent successfully' });
  } catch (error) {
    console.error('Failed to send OTP email:', error.response?.data || error.message);
    res.status(500).json({ error: 'Failed to send OTP email' });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Ascent Backend API listening on port ${PORT}`);
});
