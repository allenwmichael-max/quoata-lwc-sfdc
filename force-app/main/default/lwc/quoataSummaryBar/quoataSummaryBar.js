import { LightningElement, api } from 'lwc';

export default class QuoataSummaryBar extends LightningElement {
    @api currentBalance = 0;
    @api projectedBalance = 0;
    @api pipelineImpact = 0;
    @api unassignedCount = 0;

    get formattedPipelineImpact() {
        if (this.pipelineImpact >= 1000000) {
            return '+$' + (this.pipelineImpact / 1000000).toFixed(1) + 'M';
        }
        if (this.pipelineImpact >= 1000) {
            return '+$' + Math.round(this.pipelineImpact / 1000) + 'K';
        }
        return '+$' + this.pipelineImpact;
    }
}

