const bcrypt = require('bcryptjs'); // Industry-standard library for secure password hashing and comparison
const { isValidEmail, isValidPhone, isValidPassword } = require('../utils/validationUtils'); // Native verification suite
const otpStoreService = require('../services/otpStoreService'); // Security: Shared verification gateway

/**
 * Identity Normalization: Sri Lankan Phone Number Standardizer.
 * Ensures all phone numbers follow the +94 international format regardless of how they were typed.
 * Logic: Removes non-digits, strips leading '0', and appends '+94'.
 */
function normalizePhone(phone) {
    if (!phone) return phone;
    // Remove all characters except the digit and the optional leading plus sign to prevent injection/formatting errors.
    const clean = phone.trim().replace(/(?!^\+)\D/g, '');
    
    // Check for local format: 07xxxxxxxx (10 digits starting with zero).
    if (clean.startsWith('0') && clean.length === 10) {
        return '+94' + clean.substring(1); // Rewrite to international standard
    }
    return clean;
}

/**
 * Identity Normalization: Email Sanitizer.
 * Ensures consistent lookups by removing whitespace and forcing lowercase.
 */
function normalizeEmail(email) {
    if (!email || email.trim() === '') return null;
    return email.trim().toLowerCase();
}

/**
 * Business Logic: New User Onboarding.
 * Handles the registration of shop owners, enforcing strict identity uniqueness and password complexity.
 */
class RegisterOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository; // Interface for owner persistence
    }
    
    async execute(ownerData) {
        // --- Phase 1: Structural Validation ---
        if (!ownerData.name || ownerData.name.trim() === '') {
            throw new Error('Owner name is required');
        }
        if (!ownerData.shopName || ownerData.shopName.trim() === '') {
            throw new Error('Shop name is required');
        }
        if (!isValidPhone(ownerData.phone)) {
            throw new Error('Valid phone number is required (start with 0 or +94 and have 9 digits after)');
        }
        if (ownerData.email && !isValidEmail(ownerData.email)) {
            throw new Error('Email must end with @gmail.com');
        }
        if (!isValidPassword(ownerData.password)) {
            throw new Error('Password must be at least 8 characters long');
        }

        // --- Phase 2: Data Cleanup ---
        const normalizedPhone = normalizePhone(ownerData.phone);
        const normalizedEmail = normalizeEmail(ownerData.email);
        
        // --- Phase 3: Uniqueness Verification ---
        // Prevent duplicate accounts by checking both communication channels.
        if (normalizedEmail) {
            const existingEmail = await this.ownerRepository.findByEmail(normalizedEmail);
            if (existingEmail) {
                throw new Error('An account with this email already exists');
            }
        }
        if (normalizedPhone) {
            const existingPhone = await this.ownerRepository.findByPhone(normalizedPhone);
            if (existingPhone) {
                throw new Error('An account with this phone number already exists');
            }
        }

        // --- Phase 4.1: Security Handshake ---
        // Verify that the user has successfully completed a multi-factor OTP challenge.
        // We check either phone or email, depending on what the user provided/verified.
        const isVerified = otpStoreService.isVerified(normalizedPhone) || 
                           (normalizedEmail && otpStoreService.isVerified(normalizedEmail));
        
        if (!isVerified) {
            console.error(`[SECURITY] Registration blocked: Target not verified. (Phone: ${normalizedPhone}, Email: ${normalizedEmail})`);
            throw new Error('Identity verification required. Please request and verify an OTP first.');
        }

        // --- Phase 5: Security Transformation ---
        // We never store plain-text passwords. 10 salt rounds provides a balanced security/performance ratio.
        const hashedPassword = await bcrypt.hash(ownerData.password, 10);
        
        // Finalize storage with default active flags.
        const newOwner = await this.ownerRepository.create({ 
            ...ownerData, 
            phone: normalizedPhone, 
            email: normalizedEmail, 
            password: hashedPassword,
            status: 'approved', // Default state for new registrations
            isSuspended: false
        });

        // --- Phase 6: Proof Consumption ---
        // Invalidate the verification flags to prevent registration replay attacks.
        otpStoreService.consumeProof(normalizedPhone);
        if (normalizedEmail) otpStoreService.consumeProof(normalizedEmail);

        return newOwner;
    }
}

/**
 * Business Logic: Identity Provider & Access Control.
 * Authenticates users using multi-factor identifiers (Email or Phone).
 */
class LoginOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }

    /**
     * Authenticates an owner and returns their profile (sans password).
     */
    async execute(identifier, password) {
        console.log(`[LOGIN] Attempt for: ${identifier}`);
        let owner;

        // --- Dynamic Identity Detection ---
        // Determine if the user is logging in with an email address or a phone number.
        if (identifier && identifier.includes('@')) {
            const normalizedEmail = normalizeEmail(identifier);
            console.log(`[LOGIN] Finding by email: ${normalizedEmail}`);
            owner = await this.ownerRepository.findByEmail(normalizedEmail);
        } else {
            const normalizedPhone = normalizePhone(identifier);
            console.log(`[LOGIN] Finding by phone: ${normalizedPhone}`);
            owner = await this.ownerRepository.findByPhone(normalizedPhone);
        }
        
        // --- Security Boundary: Identity Check ---
        if (!owner) {
            console.log(`[LOGIN] User NOT found: ${identifier}`);
            // Use generic error message to prevent account enumeration attacks.
            throw new Error('Invalid email/phone or password');
        }

        // --- Account Status Enforcement ---
        if (owner.isSuspended || owner.status === 'suspended') {
            throw new Error('Your account has been suspended. Please contact admin.');
        }

        // --- Cryptographic Verification ---
        console.log(`[LOGIN] User found, comparing password.`);
        let isMatch = await bcrypt.compare(password, owner.password);
        
        console.log(`[LOGIN] Password match: ${isMatch}`);
        if (!isMatch) {
            throw new Error('Invalid email/phone or password');
        }

        // --- Data Projection ---
        // Strip the password hash before sending the object to the frontend/session.
        const { password: _, ...ownerData } = owner;
        return ownerData;
    }
}

/**
 * Business Logic: Profile Management.
 * Allows owners to update their contact details and credentials.
 */
class UpdateOwnerProfile {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }

    async execute(id, profileData) {
        const updateData = { ...profileData };
        
        // 1. Password Rotation Login: Only hash and update if a new string is actually provided.
        if (updateData.password && updateData.password.trim() !== '') {
            if (!isValidPassword(updateData.password)) {
                throw new Error('Password must be at least 8 characters long');
            }
            updateData.password = await bcrypt.hash(updateData.password, 10);
        } else {
            delete updateData.password; // Prevent overwriting with null/empty
        }
        
        // 2. Phone Update & Uniqueness Cross-Check
        if (updateData.phone) {
            if (!isValidPhone(updateData.phone)) {
                throw new Error('Valid phone number is required (start with 0 or +94 and have 9 digits after)');
            }
            updateData.phone = normalizePhone(updateData.phone);
            
            const existingPhone = await this.ownerRepository.findByPhone(updateData.phone);
            // Block update if the phone belongs to a DIFFERENT user.
            if (existingPhone && (existingPhone.id !== id && existingPhone._id !== id)) {
                throw new Error('Another account already uses this phone number');
            }
        }

        // 3. Email Update & Uniqueness Cross-Check
        if (updateData.email) {
            updateData.email = normalizeEmail(updateData.email);
            
            if (updateData.email) {
                const existingEmail = await this.ownerRepository.findByEmail(updateData.email);
                if (existingEmail && (existingEmail.id !== id && existingEmail._id !== id)) {
                    throw new Error('Another account already uses this email address');
                }
            }
        }
        
        // Persist the sanitized update set.
        return this.ownerRepository.update(id, updateData);
    }
}

/**
 * Business Logic: Credential Security.
 * Explicit workflow for rotating a known password.
 */
class ChangeOwnerPassword {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }

    async execute(id, oldPassword, newPassword) {
        // Step 1: Security Handshake - Fetch current identifying hash from the vault.
        const owner = await this.ownerRepository.getByIdWithPassword(id);
        if (!owner) {
            throw new Error('Owner not found');
        }
        
        // Step 2: Proof of Ownership - Verify the "Old Password" before allowing a change.
        const isMatch = await bcrypt.compare(oldPassword, owner.password);
        if (!isMatch) {
            throw new Error('Current password does not match');
        }
        
        // Step 3: Transformation - Encrypt the new credential.
        const hashedNewPassword = await bcrypt.hash(newPassword, 10);
        
        // Step 4: Finalize - Atomic update to the credential field.
        return this.ownerRepository.update(id, { password: hashedNewPassword });
    }
}

/**
 * Business Logic: Disaster Recovery / Forgotten Password.
 * Admin-level or verified reset of credentials.
 */
class ResetPassword {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }

    async execute(identifier, newPassword) {
        let owner;
        // Locate account by either verified channel (Email/Phone).
        if (identifier && identifier.includes('@')) {
            const normalizedEmail = normalizeEmail(identifier);
            owner = await this.ownerRepository.findByEmail(normalizedEmail);
        } else {
            const normalizedPhone = normalizePhone(identifier);
            owner = await this.ownerRepository.findByPhone(normalizedPhone);
        }

        if (!owner) {
            throw new Error('User not found with this email/phone');
        }

        // --- Security Boundary: OTP Proof Verification ---
        // Ensure the password reset is authorized by a fresh OTP handshake.
        if (!otpStoreService.isVerified(identifier)) {
            console.error(`[SECURITY] Password reset blocked: Identifier not verified. (${identifier})`);
            throw new Error('Verification required. Please verify your identity via OTP before resetting password.');
        }

        if (!isValidPassword(newPassword)) {
            throw new Error('Password must be at least 8 characters long');
        }

        // Apply new credential hash.
        const hashedNewPassword = await bcrypt.hash(newPassword, 10);
        const updatedOwner = await this.ownerRepository.update(owner.id || owner._id, { password: hashedNewPassword });

        // Cleanup: Invalidate the verification proof.
        otpStoreService.consumeProof(identifier);

        return updatedOwner;
    }
}

/**
 * Business Logic: Identity Retrieval.
 * Fetches public profile data for the active user.
 */
class GetOwnerProfile {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id) {
        return this.ownerRepository.getById(id);
    }
}

/**
 * Business Logic: System Governance.
 * Retrieves all registered merchants for the master administrative dashboard.
 */
class GetAllOwners {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }

    async execute() {
        const owners = await this.ownerRepository.getAll();
        // SECURITY FILTER: Ensure the Master Admin doesn't appear in the "Manage Business Owners" list.
        // This prevents the admin from accidentally deleting themselves via the UI.
        return owners.filter(o => o.role !== 'admin');
    }
}

/**
 * Business Logic: Administrative Account Control.
 * Allows the super-admin to modify owner details, reset passwords, or suspend businesses.
 */
class UpdateOwnerByAdmin {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }

    async execute(id, ownerData) {
        // 1. Fetch current state to ensure valid target and provide fallback data points.
        const existingOwner = await this.ownerRepository.getByIdWithPassword(id);
        if (!existingOwner) {
            return null;
        }

        // 2. Logic: Identity Synchronization & Uniqueness
        const normalizedEmail = typeof ownerData.email === 'string'
            ? ownerData.email.trim().toLowerCase()
            : existingOwner.email;
        const normalizedPhone = typeof ownerData.phone === 'string'
            ? ownerData.phone.trim()
            : existingOwner.phone;

        // Perform cross-account uniqueness checks for administrative updates.
        if (normalizedEmail) {
            const ownerWithSameEmail = await this.ownerRepository.findByEmail(normalizedEmail);
            if (ownerWithSameEmail && (ownerWithSameEmail.id !== id && ownerWithSameEmail._id !== id)) {
                throw new Error('Another account already uses this email address');
            }
        }
        if (normalizedPhone) {
            const ownerWithSamePhone = await this.ownerRepository.findByPhone(normalizedPhone);
            if (ownerWithSamePhone && (ownerWithSamePhone.id !== id && ownerWithSamePhone._id !== id)) {
                throw new Error('Another account already uses this phone number');
            }
        }

        // 3. Logic: Status & Suspension Harmonization
        // This ensures the two boolean/string fields stay in sync (e.g., status 'suspended' MUST mean isSuspended is true).
        const allowedStatusValues = new Set(['approved', 'suspended']);
        let normalizedStatus = ownerData.status;
        if (typeof normalizedStatus === 'string') {
            normalizedStatus = normalizedStatus.trim().toLowerCase();
            if (!allowedStatusValues.has(normalizedStatus)) {
                throw new Error('Invalid owner status');
            }
        }

        let normalizedSuspension = ownerData.isSuspended;
        // Rules Engine for Account State:
        if (normalizedStatus === 'approved') normalizedSuspension = false;
        if (normalizedStatus === 'suspended') normalizedSuspension = true;
        
        // Fallback rule: If admin just toggles the 'Suspension' switch without changing the dropdown.
        if (normalizedSuspension === false && normalizedStatus == null && existingOwner.status === 'suspended') {
            normalizedStatus = 'approved';
        }
        if (normalizedSuspension === true && normalizedStatus == null) {
            normalizedStatus = 'suspended';
        }

        // --- Build Sanity-Checked Update Object ---
        const updateData = {
            name: typeof ownerData.name === 'string' ? ownerData.name.trim() : existingOwner.name,
            shopName: typeof ownerData.shopName === 'string' ? ownerData.shopName.trim() : existingOwner.shopName,
            phone: normalizedPhone,
            email: normalizedEmail || '',
            status: normalizedStatus ?? existingOwner.status,
            isSuspended: typeof normalizedSuspension === 'boolean'
                ? normalizedSuspension
                : existingOwner.isSuspended,
        };

        // Admin-triggered password reset logic.
        if (ownerData.password && ownerData.password.trim() !== '') {
            if (!isValidPassword(ownerData.password)) {
                throw new Error('Password must be at least 8 characters long');
            }
            updateData.password = await bcrypt.hash(ownerData.password, 10);
        }

        return this.ownerRepository.update(id, updateData);
    }
}

/**
 * Business Logic: Total Wipeout (GDPR / Privacy Compliance).
 * Nukes an entire business entity and every single record associated with it across ALL modules.
 */
class DeleteOwner {
    constructor({ ownerRepository, productRepository, saleRepository, purchaseRepository, customerRepository, supplierRepository, creditTransactionRepository, notificationRepository, feedbackRepository }) {
        this.ownerRepository = ownerRepository;
        this.productRepository = productRepository;
        this.saleRepository = saleRepository;
        this.purchaseRepository = purchaseRepository;
        this.customerRepository = customerRepository;
        this.supplierRepository = supplierRepository;
        this.creditTransactionRepository = creditTransactionRepository;
        this.notificationRepository = notificationRepository;
        this.feedbackRepository = feedbackRepository;
    }

    /**
     * Executes a coordinated multi-collection delete.
     * This is an irreversible action.
     */
    async execute(id) {
        console.log(`[WIPE] Starting full data wipe for owner: ${id}`);
        
        // Logic: Mass parallelism. We fire 'deleteMany' commands across the entire platform schema.
        // This ensures no "orphan data" remains in the DB after an owner is deleted.
        await Promise.all([
            this.productRepository.model.deleteMany({ ownerId: id }),
            this.customerRepository.model.deleteMany({ ownerId: id }),
            this.supplierRepository.model.deleteMany({ ownerId: id }),
            this.purchaseRepository.model.deleteMany({ ownerId: id }),
            this.saleRepository.model.deleteMany({ ownerId: id }),
            this.creditTransactionRepository.model.deleteMany({ ownerId: id }),
            this.notificationRepository.model.deleteMany({ ownerId: id }),
            this.feedbackRepository.model.deleteMany({ ownerId: id })
        ]);

        console.log(`[WIPE] Related data cleared. Deleting owner record.`);
        // Note: The owner record is deleted last to maintain referential integrity in logs until the end.
        return this.ownerRepository.delete(id);
    }
}

/**
 * Business Logic: Pre-Registration Validation Service.
 * Allows the UI to check if an email/phone is free before the user completes a long form.
 */
class CheckAvailability {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    
    async execute({ phone, email }) {
        if (!phone && !email) {
            throw new Error('Phone or Email is required for check');
        }

        // Check phone availability
        if (phone) {
            const normalizedPhone = normalizePhone(phone);
            const existingPhone = await this.ownerRepository.findByPhone(normalizedPhone);
            if (existingPhone) {
                return { available: false, message: 'An account with this phone number already exists' };
            }
        }

        // Check email availability
        if (email) {
            const normalizedEmail = normalizeEmail(email);
            if (normalizedEmail) {
                const existingEmail = await this.ownerRepository.findByEmail(normalizedEmail);
                if (existingEmail) {
                    return { available: false, message: 'An account with this email already exists' };
                }
            }
        }

        return { available: true }; // Target is clean for a new registration
    }
}

// Module Exports: Exposes the primary Authentication and Identity Management suite.
module.exports = { 
    RegisterOwner, 
    LoginOwner, 
    GetOwnerProfile, 
    UpdateOwnerProfile, 
    ChangeOwnerPassword, 
    GetAllOwners, 
    ResetPassword, 
    UpdateOwnerByAdmin, 
    DeleteOwner, 
    CheckAvailability 
};
