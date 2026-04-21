const path = require('path');
const nodemailer = require('nodemailer');
const otpStoreService = require('../services/otpStoreService');
const { normalizeEmail, normalizePhone } = require('./authUseCases');

/**
 * Normalization Helper: Selects the correct standardizer based on identifier type.
 */
function normalizeIdentifier(identifier) {
    if (!identifier) return identifier;
    return identifier.includes('@') ? normalizeEmail(identifier) : normalizePhone(identifier);
}

/**
 * Logic: Dual-Mode OTP Provisioner.
 * Rationale: Manages the lifecycle of security pins, offering both real email 
 *   delivery and a developer-safe "terminal mockup" for phone verification.
 */
class RequestOtp {
    async execute({ target, method }) {
        // --- Phase 1: Identity Normalization ---
        // Rationale: Ensures consistency between request, verification, and auth flows.
        const normalizedTarget = normalizeIdentifier(target);

        // --- Phase 1.1: Throttling Protection ---
        if (otpStoreService.isThrottled(normalizedTarget)) {
            throw new Error('Please wait 60 seconds before requesting a new code.');
        }

        // Step 1: Generate a secure 6-digit pin.
        const pin = Math.floor(100000 + Math.random() * 900000).toString();
        const expiresAt = Date.now() + 5 * 60 * 1000; // 5 minute TTL

        // Step 2: Persist the pin in the registry.
        otpStoreService.setPin(normalizedTarget, pin, expiresAt);

        // Step 3: Delivery Orchestration.
        if (method === 'email') {
            await this._sendEmail(normalizedTarget, pin);
        } else if (method === 'phone') {
            await this._logToTerminal(normalizedTarget, pin);
        } else {
            throw new Error('Invalid verification method');
        }

        return { success: true, message: `OTP sent via ${method}` };
    }

    /**
     * Internal: Real-world Email Dispatcher.
     * Strategy: Uses Ethereal Mail for zero-setup testing, or Gmail for production.
     */
    async _sendEmail(email, pin) {
        let transporter;

        // Strategy: Use Gmail/SMTP if configured in .env, otherwise fallback to Ethereal Testing.
        if (process.env.EMAIL_USER && process.env.EMAIL_PASS) {
            transporter = nodemailer.createTransport({
                service: 'gmail',
                auth: {
                    user: process.env.EMAIL_USER,
                    pass: process.env.EMAIL_PASS,
                },
            });
        } else {
            // Development Fallback: Ethereal Mail (No account required).
            console.log('\x1b[33m%s\x1b[0m', '⚠️ [OTP] EMAIL_USER/.PASS not set. Using Ethereal Mail for testing...');
            const testAccount = await nodemailer.createTestAccount();
            transporter = nodemailer.createTransport({
                host: "smtp.ethereal.email",
                port: 587,
                secure: false, 
                auth: {
                    user: testAccount.user,
                    pass: testAccount.pass,
                },
            });
        }

        const info = await transporter.sendMail({
            from: '"ClickBuy Support" <support@clickbuy.app>',
            to: email,
            subject: "Your Verification Code",
            messageId: `<otp.${Date.now()}.${pin}@clickbuy.app>`, // Meaningful Message-ID for tracking
            text: `Your ClickBuy verification code is: ${pin}. It expires in 5 minutes.`,
            html: `
                <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px; max-width: 500px;">
                    <div style="text-align: center; margin-bottom: 20px;">
                        <img src="cid:logo" alt="ClickBuy Logo" style="width: 80px; height: 80px; border-radius: 16px;">
                    </div>
                    <h2 style="color: #2D3436; text-align: center;">Welcome to ClickBuy!</h2>
                    <p style="text-align: center; color: #636E72;">Enter the following code to verify your identity:</p>
                    <div style="font-size: 32px; font-weight: bold; padding: 20px; background: #F9F9F9; text-align: center; color: #00B894; border-radius: 8px; margin: 20px 0; letter-spacing: 5px;">
                        ${pin}
                    </div>
                    <p style="color: #636E72; font-size: 12px; margin-top: 20px; text-align: center;">
                        This code will expire in 5 minutes. If you didn't request this, you can safely ignore this email.
                    </p>
                    <div style="margin-top: 30px; border-top: 1px solid #eee; pt: 10px; color: #b2bec3; font-size: 10px; text-align: center;">
                        Ref: ${Date.now().toString().slice(-6)} | Requested at: ${new Date().toLocaleTimeString()}
                    </div>
                </div>
            `,
            attachments: [{
                filename: 'logo.png',
                // Portability: Use relative path resolve instead of hardcoded Windows-specific path
                path: path.resolve(__dirname, '../../../frontend/assets/images/app_icon.png'),
                cid: 'logo', // Matches src="cid:logo" in HTML
                contentType: 'image/png'
            }]
        });

        // Diagnostic: Log the preview URL for free testing accounts.
        if (!process.env.EMAIL_USER) {
            console.log('\x1b[36m%s\x1b[0m', '📩 [OTP] Email Preview Link: ' + nodemailer.getTestMessageUrl(info));
        }
        console.log('\x1b[36m%s\x1b[0m', '🆔 [OTP] Message-ID: ' + info.messageId);
    }

    /**
     * Internal: Developer Mockup Dispatcher.
     * Rationale: Prints the code to the terminal, allowing immediate verification without carrier costs.
     */
    async _logToTerminal(phone, pin) {
        console.log('\n----------------------------------------');
        console.log('\x1b[32m%s\x1b[0m', '📱 [OTP MOCKUP]');
        console.log(`Target Number: ${phone}`);
        console.log('\x1b[1m\x1b[32m%s\x1b[0m', `VERIFICATION CODE: ${pin}`);
        console.log('----------------------------------------\n');
    }
}

/**
 * Logic: Identity Authenticator.
 * Rationale: Compares the user-provided pin against the registered session.
 */
class VerifyOtp {
    async execute({ target, pin }) {
        const normalizedTarget = normalizeIdentifier(target);
        const record = otpStoreService.getPin(normalizedTarget);

        if (!record) {
            throw new Error('No active verification session found');
        }

        if (Date.now() > record.expiresAt) {
            otpStoreService.deletePin(normalizedTarget);
            throw new Error('Verification code has expired');
        }

        if (record.pin !== pin) {
            const attempts = otpStoreService.incrementAttempts(normalizedTarget);
            const MAX_ATTEMPTS = 5;
            
            if (attempts >= MAX_ATTEMPTS) {
                otpStoreService.deletePin(normalizedTarget);
                throw new Error('Too many invalid attempts. This verification code has been deactivated for security. Please request a new one.');
            }
            
            throw new Error(`Invalid verification code. ${MAX_ATTEMPTS - attempts} attempts remaining.`);
        }

        // Action: Mark this identity as verified in the shared store.
        // This proof allows the Auth Use Cases to proceed with registration or reset.
        otpStoreService.markAsVerified(normalizedTarget);
        
        // Action: Cleanup the PIN record on success to prevent reuse.
        otpStoreService.deletePin(normalizedTarget);
        
        return { success: true, message: 'Identity verified successfully' };
    }
}

module.exports = { RequestOtp, VerifyOtp };
