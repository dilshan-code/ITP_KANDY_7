const bcrypt = require('bcryptjs');

function normalizePhone(phone) {
    if (!phone) return phone;
    const trimmed = phone.trim();
    if (trimmed.startsWith('0') && trimmed.length === 10) {
        return '+94' + trimmed.substring(1);
    }
    return trimmed;
}


// This use case handles the registration of a new shop owner.
class RegisterOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(ownerData) {
        const normalizedPhone = normalizePhone(ownerData.phone);
        
        // Check if email already exists, if provided
        if (ownerData.email) {
            const existingEmail = await this.ownerRepository.findByEmail(ownerData.email);
            if (existingEmail) {
                throw new Error('An account with this email already exists');
            }
        }
        // Check if phone already exists
        if (normalizedPhone) {
            const existingPhone = await this.ownerRepository.findByPhone(normalizedPhone);
            if (existingPhone) {
                throw new Error('An account with this phone number already exists');
            }
        }
        // Hash the password before saving
        const hashedPassword = await bcrypt.hash(ownerData.password, 10);
        return this.ownerRepository.create({ ...ownerData, phone: normalizedPhone, password: hashedPassword });
    }
}

// This use case handles the login process for an existing owner.
class LoginOwner {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    // Checks if the email or phone and password match a record in the database.
    async execute(identifier, password) {
        let owner;
        if (identifier && identifier.includes('@')) {
            owner = await this.ownerRepository.findByEmail(identifier);
        } else {
            const normalizedPhone = normalizePhone(identifier);
            owner = await this.ownerRepository.findByPhone(normalizedPhone);
        }
        
        if (!owner) {
            throw new Error('Invalid email/phone or password');
        }
        const isMatch = await bcrypt.compare(password, owner.password);
        if (!isMatch) {
            throw new Error('Invalid email/phone or password');
        }
        // Return owner data without password
        const { password: _, ...ownerData } = owner;
        return ownerData;
    }
}

class UpdateOwnerProfile {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id, profileData) {
        // Do not allow updating password through this use case
        const { password, ...updateData } = profileData;
        
        if (updateData.phone) {
            updateData.phone = normalizePhone(updateData.phone);
        }
        
        return this.ownerRepository.update(id, updateData);
    }
}

// This use case allows an owner to change their account password.
class ChangeOwnerPassword {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id, oldPassword, newPassword) {
        const owner = await this.ownerRepository.getById(id);
        if (!owner) {
            throw new Error('Owner not found');
        }

        // We need the password from the repository (which might not be in the toJSON output)
        // Let's check how getById is implemented in the repository.
        // The repository getById returns owner.toJSON() which might exclude password.
        // I should probably check the raw repository implementation or add a method.
        
        // Actually, looking at FirestoreOwnerRepository.js:
        // getById returns owner.toJSON()
        // findByPhone/findByEmail returns the raw data including password.
        
        // I'll use a internal method or fetch by id directly from collection if needed.
        // For now, let's assume the repository needs a way to get the full data including password.
        
        const rawOwner = await this.ownerRepository.collection.doc(id).get();
        if (!rawOwner.exists) {
            throw new Error('Owner not found');
        }
        const ownerData = rawOwner.data();
        
        const isMatch = await bcrypt.compare(oldPassword, ownerData.password);
        if (!isMatch) {
            throw new Error('Current password does not match');
        }
        
        const hashedNewPassword = await bcrypt.hash(newPassword, 10);
        return this.ownerRepository.update(id, { password: hashedNewPassword });
    }
}

class GetOwnerProfile {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute(id) {
        return this.ownerRepository.getById(id);
    }
}

class GetAllOwners {
    constructor(ownerRepository) {
        this.ownerRepository = ownerRepository;
    }
    async execute() {
        return this.ownerRepository.getAll();
    }
}

module.exports = { RegisterOwner, LoginOwner, GetOwnerProfile, UpdateOwnerProfile, ChangeOwnerPassword, GetAllOwners };
