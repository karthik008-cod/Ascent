require('dotenv').config();
const express = require('express');
const cors = require('cors');
const axios = require('axios');
const mongoose = require('mongoose');

const authRoutes = require('./routes/auth');
const syncRoutes = require('./routes/sync');

const app = express();
const PORT = process.env.PORT || 3000;

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log('MongoDB connected'))
  .catch(err => console.log('MongoDB connection error:', err));

// Middleware
app.use(cors());
app.use(express.json());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/sync', syncRoutes);

// Routes
app.post('/api/send-otp', async (req, res) => {
  const { email, otp, purpose } = req.body;
  
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

  // Context-aware email content
  const emailPurpose = purpose || 'login';
  
  let subject, heading, message, ctaText, iconEmoji, accentColor;
  
  switch (emailPurpose) {
    case 'registration':
      subject = 'Welcome to Ascent — Verify Your Email';
      heading = 'Welcome Aboard! 🚀';
      message = 'You\'re one step away from starting your productivity journey. Enter the code below in the app to create your account.';
      ctaText = 'Verify & Create Account';
      iconEmoji = '🎯';
      accentColor = '#6C63FF';
      break;
    case 'password_reset':
      subject = 'Ascent — Password Reset Code';
      heading = 'Reset Your Password 🔐';
      message = 'We received a request to reset your password. Use the code below to verify your identity and set a new password.';
      ctaText = 'Reset Password';
      iconEmoji = '🔑';
      accentColor = '#FF6B6B';
      break;
    case 'login':
    default:
      subject = 'Ascent — Your Sign-In Code';
      heading = 'Sign In to Ascent ✨';
      message = 'Use the code below to securely sign in to your Ascent account. No password needed!';
      ctaText = 'Sign In Now';
      iconEmoji = '⚡';
      accentColor = '#6C63FF';
      break;
  }

  // Split OTP into individual digits for the styled display
  const otpDigits = otp.split('').map(d => 
    `<td style="padding: 0 4px;">
      <div style="width: 44px; height: 56px; background: ${accentColor}; border-radius: 10px; font-size: 26px; font-weight: 700; color: #ffffff; line-height: 56px; text-align: center; font-family: 'SF Mono', 'Roboto Mono', Consolas, monospace;">${d}</div>
    </td>`
  ).join('');
  
  const htmlContent = `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body style="margin: 0; padding: 0; background-color: #0B0C10; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0B0C10;">
    <tr>
      <td align="center" style="padding: 40px 20px;">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="max-width: 520px; background-color: #1A1C23; border-radius: 20px; overflow: hidden; border: 1px solid #2A2D37;">
          
          <!-- Header accent bar -->
          <tr>
            <td style="height: 4px; background: linear-gradient(90deg, ${accentColor}, #E5C158);"></td>
          </tr>
          
          <!-- Logo & Brand -->
          <tr>
            <td align="center" style="padding: 36px 40px 20px;">
              <div style="font-size: 36px; margin-bottom: 8px;">${iconEmoji}</div>
              <h1 style="margin: 0; font-size: 24px; font-weight: 700; color: #FFFFFF; letter-spacing: -0.5px;">${heading}</h1>
            </td>
          </tr>
          
          <!-- Message -->
          <tr>
            <td style="padding: 0 40px 28px;">
              <p style="margin: 0; font-size: 15px; line-height: 24px; color: #9CA3AF; text-align: center;">${message}</p>
            </td>
          </tr>
          
          <!-- OTP Code -->
          <tr>
            <td align="center" style="padding: 0 40px 12px;">
              <table role="presentation" cellspacing="0" cellpadding="0">
                <tr>
                  ${otpDigits}
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Expiry notice -->
          <tr>
            <td align="center" style="padding: 0 40px 32px;">
              <p style="margin: 0; font-size: 13px; color: #6B7280;">⏱ This code expires in <strong style="color: #E5C158;">10 minutes</strong></p>
            </td>
          </tr>
          
          <!-- Divider -->
          <tr>
            <td style="padding: 0 40px;">
              <div style="height: 1px; background-color: #2A2D37;"></div>
            </td>
          </tr>
          
          <!-- Security footer -->
          <tr>
            <td style="padding: 24px 40px 36px;">
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0">
                <tr>
                  <td width="24" valign="top" style="padding-right: 10px;">
                    <div style="font-size: 16px;">🛡️</div>
                  </td>
                  <td>
                    <p style="margin: 0; font-size: 12px; line-height: 18px; color: #6B7280;">If you didn't request this code, you can safely ignore this email. Your account remains secure.</p>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          
          <!-- Brand footer -->
          <tr>
            <td align="center" style="padding: 20px 40px 28px; background-color: #13141A;">
              <p style="margin: 0; font-size: 13px; font-weight: 600; color: #E5C158; letter-spacing: 2px;">ASCENT</p>
              <p style="margin: 6px 0 0; font-size: 11px; color: #4B5563;">Level up your productivity, one mission at a time.</p>
            </td>
          </tr>
          
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`;
  
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
    subject: subject,
    htmlContent: htmlContent,
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

// Debug env endpoint
app.get('/api/debug-env', (req, res) => {
  const uri = process.env.MONGO_URI || '';
  const maskedUri = uri.replace(/:([^:@]+)@/, ':***@');
  res.status(200).json({ mongoUri: maskedUri, nodeVersion: process.version });
});

// Start Server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Ascent Backend API listening on port ${PORT}`);
});
