class SubmitFeedback {
    constructor(feedbackRepository) {
        this.feedbackRepository = feedbackRepository;
    }

    async execute(feedbackData, ownerId, ownerName) {
        if (!feedbackData.message || feedbackData.message.trim() === '') {
            throw new Error('Feedback message is required');
        }
        if (!feedbackData.category) {
            throw new Error('Feedback category is required');
        }

        return this.feedbackRepository.create({
            ...feedbackData,
            ownerId,
            ownerName
        });
    }
}

class GetAllFeedback {
    constructor(feedbackRepository) {
        this.feedbackRepository = feedbackRepository;
    }

    async execute() {
        return this.feedbackRepository.getAll();
    }
}

class DeleteFeedback {
    constructor(feedbackRepository) {
        this.feedbackRepository = feedbackRepository;
    }

    async execute(id) {
        return this.feedbackRepository.delete(id);
    }
}

module.exports = {
    SubmitFeedback,
    GetAllFeedback,
    DeleteFeedback
};
