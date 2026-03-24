// SupplierController handles the relationships with the companies or people who provide products to the shop.
class SupplierController {
    constructor({ getAllSuppliers, getSupplierById, createSupplier, updateSupplier, deleteSupplier }) {
        this.getAllSuppliers = getAllSuppliers;
        this.getSupplierById = getSupplierById;
        this.createSupplier = createSupplier;
        this.updateSupplier = updateSupplier;
        this.deleteSupplier = deleteSupplier;
    }

    // Lists every supplier recorded in the system.
    async getAll(req, res) {
        try {
            const suppliers = await this.getAllSuppliers.execute();
            res.json({ success: true, data: suppliers });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Finds a specific supplier using their ID.
    async getById(req, res) {
        try {
            const supplier = await this.getSupplierById.execute(req.params.id);
            if (!supplier) return res.status(404).json({ success: false, error: 'Supplier not found' });
            res.json({ success: true, data: supplier });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Adds a new supplier to the business database.
    async create(req, res) {
        try {
            const supplier = await this.createSupplier.execute(req.body);
            res.status(201).json({ success: true, data: supplier });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Updates the contact info or details for an existing supplier.
    async update(req, res) {
        try {
            const supplier = await this.updateSupplier.execute(req.params.id, req.body);
            if (!supplier) return res.status(404).json({ success: false, error: 'Supplier not found' });
            res.json({ success: true, data: supplier });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }

    // Removes a supplier from the list.
    async delete(req, res) {
        try {
            const deleted = await this.deleteSupplier.execute(req.params.id);
            if (!deleted) return res.status(404).json({ success: false, error: 'Supplier not found' });
            res.json({ success: true, message: 'Supplier deleted' });
        } catch (error) {
            res.status(500).json({ success: false, error: error.message });
        }
    }
}

module.exports = SupplierController;
