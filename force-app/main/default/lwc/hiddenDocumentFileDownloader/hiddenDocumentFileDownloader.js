import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import downloadAndAttachFile from '@salesforce/apex/MuleSoftFileDownload.downloadAndAttachFile';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
const FIELDS = [
    'DocumentChecklistItem.MarinerExternalID__c',
    'DocumentChecklistItem.LastDownloadDate__c'
];

export default class DocumentChecklistFileDownloader extends LightningElement {
    @api recordId;
    fileId;
    lastDownloadDate;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    recordData({ error, data }) {
        if (data) {
            this.fileId = data.fields.MarinerExternalID__c?.value;
            this.lastDownloadDate = data.fields.LastDownloadDate__c?.value;
            console.log('Fetched fileId:', this.fileId);
            console.log('Fetched lastDownloadDate:', this.lastDownloadDate);

            if (this.fileId) {
                const today = new Date().toISOString().split('T')[0]; // format: YYYY-MM-DD

                if (this.lastDownloadDate === today) {
                    return;
                }

                this.downloadFile();  
            } else {
                this.showToast('Missing File ID', 'File ID (MarinerExternalID__c) is missing. Therefore, no file will be downloaded. Please provide a valid File ID to proceed with the download. ', 'info');
            }
        } else if (error) {
            console.error('Error fetching record:', error);
            this.showToast('Error', 'Failed to fetch record data.', 'error');
        }
    }

     downloadFile() {
        try {
             downloadAndAttachFile({
                fileId: this.fileId,
                parentRecordId: this.recordId
            })
        } catch (error) {
            console.error('Error:', error);
            const message = error?.body?.message || error?.message || 'Failed to download file.';
            this.showToast('Error', message, 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}