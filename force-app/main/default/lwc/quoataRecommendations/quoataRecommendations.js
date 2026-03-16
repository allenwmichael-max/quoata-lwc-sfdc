import { LightningElement, api, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { updateRecord } from 'lightning/uiRecordApi';
import ACCOUNT_OWNER_FIELD from '@salesforce/schema/Account.OwnerId';
import ACCOUNT_ID_FIELD from '@salesforce/schema/Account.Id';
import getRecommendations from '@salesforce/apex/QuoataRecommendationController.getRecommendations';
import acceptRecommendation from '@salesforce/apex/QuoataRecommendationController.acceptRecommendation';
import rejectRecommendation from '@salesforce/apex/QuoataRecommendationController.rejectRecommendation';
import snoozeRecommendation from '@salesforce/apex/QuoataRecommendationController.snoozeRecommendation';
import acceptAllRecommendations from '@salesforce/apex/QuoataRecommendationController.acceptAllRecommendations';
import Id from '@salesforce/user/Id';

export default class QuoataRecommendations extends LightningElement {
    @api maxRecommendations = 10;
    @api autoRefreshMinutes = 15;

    @track recommendations = [];
    @track summaryData = {};
    @track isLoading = true;
    @track isProcessing = false;
    @track error = null;

    currentUserId = Id;
    totalCount = 0;
    refreshInterval;

    get isEmpty() {
        return !this.isLoading && !this.error && this.recommendations.length === 0;
    }

    get pendingCount() {
        return this.recommendations.length;
    }

    get hasMore() {
        return this.totalCount > this.recommendations.length;
    }

    get quoataAppUrl() {
        return 'https://app.quoata.io/recommendations';
    }

    connectedCallback() {
        this.loadRecommendations();

        if (this.autoRefreshMinutes > 0) {
            this.refreshInterval = setInterval(() => {
                this.loadRecommendations();
            }, this.autoRefreshMinutes * 60 * 1000);
        }
    }

    disconnectedCallback() {
        if (this.refreshInterval) {
            clearInterval(this.refreshInterval);
        }
    }

    async loadRecommendations() {
        try {
            this.isLoading = true;
            this.error = null;

            const result = await getRecommendations({
                managerId: this.currentUserId,
                maxResults: this.maxRecommendations
            });

            const data = JSON.parse(result);

            this.recommendations = (data.recommendations || []).map((rec) => ({
                ...rec,
                typeClass: this.getTypeClass(rec.type),
                typeLabel: this.getTypeLabel(rec.type),
                typeBadgeClass: this.getTypeBadgeClass(rec.type),
                icpScoreClass: this.getIcpScoreClass(rec.icpScore)
            }));

            this.summaryData = data.summary || {};
            this.totalCount = data.totalCount || 0;
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Quoata LWC Error:', err);
            this.error = 'Unable to load recommendations. Please try again.';
        } finally {
            this.isLoading = false;
        }
    }

    async handleAccept(event) {
        const recId = event.detail.recommendationId;
        const rec = this.recommendations.find((r) => r.id === recId);

        if (!rec) {
            return;
        }

        try {
            this.isProcessing = true;

            if (rec.proposedOwnerId && rec.accountId) {
                const fields = {};
                fields[ACCOUNT_ID_FIELD.fieldApiName] = rec.accountId;
                fields[ACCOUNT_OWNER_FIELD.fieldApiName] = rec.proposedOwnerId;
                await updateRecord({ fields });
            }

            await acceptRecommendation({
                recommendationId: recId
            });

            this.recommendations = this.recommendations.filter((r) => r.id !== recId);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Recommendation accepted',
                    message: `${rec.accountName} assigned to ${rec.proposedOwnerName}`,
                    variant: 'success'
                })
            );
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Accept error:', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to apply recommendation. Please try again.',
                    variant: 'error'
                })
            );
        } finally {
            this.isProcessing = false;
        }
    }

    async handleReject(event) {
        const recId = event.detail.recommendationId;

        try {
            this.isProcessing = true;

            await rejectRecommendation({ recommendationId: recId });

            this.recommendations = this.recommendations.filter((r) => r.id !== recId);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Recommendation dismissed',
                    message: 'This recommendation has been removed.',
                    variant: 'info'
                })
            );
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Reject error:', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to dismiss recommendation.',
                    variant: 'error'
                })
            );
        } finally {
            this.isProcessing = false;
        }
    }

    async handleSnooze(event) {
        const recId = event.detail.recommendationId;

        try {
            this.isProcessing = true;

            await snoozeRecommendation({ recommendationId: recId });

            this.recommendations = this.recommendations.filter((r) => r.id !== recId);

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Snoozed',
                    message: 'This recommendation will reappear in 7 days.',
                    variant: 'info'
                })
            );
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Snooze error:', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Failed to snooze recommendation.',
                    variant: 'error'
                })
            );
        } finally {
            this.isProcessing = false;
        }
    }

    async handleAcceptAll() {
        try {
            this.isProcessing = true;

            const recIds = this.recommendations.map((r) => r.id);

            const updatePromises = this.recommendations
                .filter((r) => r.proposedOwnerId && r.accountId)
                .map((r) => {
                    const fields = {};
                    fields[ACCOUNT_ID_FIELD.fieldApiName] = r.accountId;
                    fields[ACCOUNT_OWNER_FIELD.fieldApiName] = r.proposedOwnerId;
                    return updateRecord({ fields });
                });

            await Promise.all(updatePromises);

            await acceptAllRecommendations({ recommendationIds: recIds });

            this.recommendations = [];

            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'All recommendations accepted',
                    message: `${recIds.length} territory changes applied successfully.`,
                    variant: 'success'
                })
            );
        } catch (err) {
            // eslint-disable-next-line no-console
            console.error('Accept all error:', err);
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error',
                    message: 'Some changes may have failed. Please refresh and review.',
                    variant: 'error'
                })
            );
        } finally {
            this.isProcessing = false;
        }
    }

    handleRefresh() {
        this.loadRecommendations();
    }

    getTypeClass(type) {
        const classes = {
            new_assignment: 'type-indicator-new',
            reassignment: 'type-indicator-reassign',
            rebalance: 'type-indicator-rebalance'
        };
        return classes[type] || 'type-indicator-default';
    }

    getTypeLabel(type) {
        const labels = {
            new_assignment: 'New assignment',
            reassignment: 'Reassignment',
            rebalance: 'Rebalance'
        };
        return labels[type] || type;
    }

    getTypeBadgeClass(type) {
        const classes = {
            new_assignment: 'badge-new',
            reassignment: 'badge-reassign',
            rebalance: 'badge-rebalance'
        };
        return classes[type] || 'badge-default';
    }

    getIcpScoreClass(score) {
        if (score >= 85) return 'icp-high';
        if (score >= 70) return 'icp-medium';
        return 'icp-low';
    }
}

