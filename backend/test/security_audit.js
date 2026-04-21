const BASE_URL = 'http://localhost:3000';

/**
 * Security Audit Script: ClickBuy Backend.
 * Uses native fetch (Node 18+) to simulate various attack vectors.
 */

async function runAudit() {
    console.log('--- STARTING SECURITY AUDIT ---\n');

    try {
        // 1. Identity Spoofing (Impersonation)
        await testIdentitySpoofing();

        // 2. OTP Bypass (Registration)
        await testOtpBypass();

        // 3. OTP Brute Force Protection
        await testOtpBruteForce();

        // 4. OTP Throttling (Rate Limiting)
        await testOtpThrottling();

        // 5. NoSQL Injection (Login)
        await testNoSqlInjection();
    } catch (e) {
        console.error('CRITICAL AUDIT ERROR:', e.message);
    }

    console.log('\n--- AUDIT COMPLETE ---');
}

/**
 * Test: Accessing private data by spoofing x-owner-id header.
 */
async function testIdentitySpoofing() {
    console.log('[TEST 1] Identity Spoofing...');
    try {
        const spoofedId = 'admin_master_001';
        const response = await fetch(`${BASE_URL}/api/auth/profile/${spoofedId}`, {
            headers: {
                'x-owner-id': spoofedId,
                'x-owner-name': 'Hacker'
            }
        });
        const result = await response.json();
        if (response.ok && result.success) {
            console.error('❌ VULNERABILITY FOUND: Identity spoofing successful. Accessed profile without token.');
        } else {
            console.log('✅ PASSED: Identity correctly guarded.');
        }
    } catch (e) {
        console.log('⚠️ Test Error:', e.message);
    }
}

/**
 * Test: Registering without performing OTP verification.
 */
async function testOtpBypass() {
    console.log('[TEST 2] OTP Bypass Registration...');
    try {
        // Use a random number each time to avoid "already exists" errors
        const rand = Math.floor(1000000 + Math.random() * 9000000);
        const phone = `077${rand}`;
        
        const payload = {
            phone: phone,
            password: 'password123',
            shopName: 'Hacker Shop',
            name: 'Hacker'
        };
        const response = await fetch(`${BASE_URL}/api/auth/register`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const result = await response.json();
        const errorMsg = result.error || '';
        
        if (response.status === 401 && errorMsg.includes('verification required')) {
            console.log('✅ PASSED: Registration blocked without OTP.');
        } else if (response.ok) {
            console.error('❌ VULNERABILITY FOUND: Registered without OTP verification.');
        } else {
            console.log(`ℹ️ Info: Returned status ${response.status} - ${errorMsg}`);
        }
    } catch (e) {
        console.log('⚠️ Test Error:', e.message);
    }
}

/**
 * Test: Brute forcing the OTP PIN.
 */
async function testOtpBruteForce() {
    console.log('[TEST 3] OTP Brute Force...');
    try {
        const rand = Math.floor(1000000 + Math.random() * 9000000);
        const target = `077${rand}`;

        // 1. Request OTP
        await fetch(`${BASE_URL}/api/otp/request`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ target, method: 'phone' })
        });

        // 2. Try 6 wrong PINs
        for (let i = 1; i <= 6; i++) {
            const response = await fetch(`${BASE_URL}/api/otp/verify`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ target, pin: '00000' + i })
            });
            const result = await response.json();
            const errorMsg = result.error || '';
            
            if (i === 6) {
                if (errorMsg.includes('Too many invalid attempts')) {
                    console.log('✅ PASSED: OTP locked after 5 failed attempts.');
                } else {
                    console.error('❌ VULNERABILITY FOUND: OTP still active or error unexpected:', errorMsg);
                }
            }
        }
    } catch (e) {
        console.log('⚠️ Test Error:', e.message);
    }
}

/**
 * Test: Requesting multiple OTPs rapidly.
 */
async function testOtpThrottling() {
    console.log('[TEST 4] OTP Throttling...');
    try {
        const rand = Math.floor(1000000 + Math.random() * 9000000);
        const target = `077${rand}`;

        // First request
        await fetch(`${BASE_URL}/api/otp/request`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ target, method: 'phone' })
        });

        // Immediate second request
        const response = await fetch(`${BASE_URL}/api/otp/request`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ target, method: 'phone' })
        });
        const result = await response.json();
        const errorMsg = result.error || '';

        if (response.status === 400 && errorMsg.includes('wait 60 seconds')) {
            console.log('✅ PASSED: Rate limit applied.');
        } else if (response.ok) {
            console.error('❌ VULNERABILITY FOUND: No throttling detected.');
        } else {
            console.log(`ℹ️ Info: Returned status ${response.status} - ${errorMsg}`);
        }
    } catch (e) {
        console.log('⚠️ Test Error:', e.message);
    }
}

/**
 * Test: NoSQL Operator Injection.
 * Attempt to login using an object instead of a string to bypass equality checks.
 */
async function testNoSqlInjection() {
    console.log('[TEST 5] NoSQL Injection (Login)...');
    try {
        const payload = {
            identifier: { "$gt": "" },
            password: { "$gt": "" }
        };
        const response = await fetch(`${BASE_URL}/api/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const result = await response.json();
        
        // If it returns success or profile data, it's vulnerable.
        // Even if it returns 500 but because of a DB error (indicating the object reached the DB), it's a concern.
        if (response.ok && result.success) {
            console.error('❌ VULNERABILITY FOUND: NoSQL content injection successful.');
        } else {
            console.log('✅ PASSED: Input sanitized or rejected.');
        }
    } catch (e) {
        console.log('⚠️ Test Error:', e.message);
    }
}

runAudit();
