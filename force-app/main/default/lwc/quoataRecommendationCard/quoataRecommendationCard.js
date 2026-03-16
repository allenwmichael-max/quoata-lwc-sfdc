import { LightningElement, api } from 'lwc';

export default class QuoataRecommendationCard extends LightningElement {
    @api recommendation;
    @api isProcessing = false;

    get accountUrl() {
        if (this.recommendation && this.recommendation.accountId) {
            return '/' + this.recommendation.accountId;
        }
        return '#';
    }

    get typeIndicatorClass() {
        return 'type-indicator ' + (this.recommendation ? this.recommendation.typeClass : '');
    }

    get typeBadgeClass() {
        return 'badge ' + (this.recommendation ? this.recommendation.typeBadgeClass : '');
    }

    get icpBadgeClass() {
        if (!this.recommendation) return 'badge badge-icp';
        return 'badge ' + this.recommendation.icpScoreClass;
    }

    handleAccept() {
        this.dispatchEvent(
            new CustomEvent('accept', {
                detail: { recommendationId: this.recommendation.id },
                bubbles: true,
                composed: true
            })
        );
    }

    handleReject() {
        this.dispatchEvent(
            new CustomEvent('reject', {
                detail: { recommendationId: this.recommendation.id },
                bubbles: true,
                composed: true
            })
        );
    }

    handleSnooze() {
        this.dispatchEvent(
            new CustomEvent('snooze', {
                detail: { recommendationId: this.recommendation.id },
                bubbles: true,
                composed: true
            })
        );
    }
}

