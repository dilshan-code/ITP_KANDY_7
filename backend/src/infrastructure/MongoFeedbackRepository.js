const { v4: uuidv4 } = require('uuid');
const FeedbackModel = require('./models/Feedback');
const Feedback = require('../domain/entities/Feedback');
const IFeedbackRepository = require('../domain/repositories/IFeedbackRepository');

class MongoFeedbackRepository extends IFeedbackRepository {
    constructor() {
        super();
        this.model = FeedbackModel;
    }

    async create(feedbackData) {
        const now = new Date().toISOString();
        const data = {
            _id: feedbackData.id || uuidv4(),
            ownerId: feedbackData.ownerId,
            ownerName: feedbackData.ownerName,
            category: feedbackData.category,
            message: feedbackData.message,
            createdAt: now
        };

        const [doc] = await this.model.create([data]);
        return new Feedback({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
    }

    async getAll() {
        const docs = await this.model.find().sort({ createdAt: -1 }).exec();
        return docs.map(doc => {
            return new Feedback({ id: doc._id.toString(), ...doc.toJSON() }).toJSON();
        });
    }

    async delete(id) {
        const result = await this.model.deleteOne({ _id: id });
        return result.deletedCount > 0;
    }
}

module.exports = MongoFeedbackRepository;
