import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import getFileMetadata from '@salesforce/apex/MuleSoftFileDownload.getFileMetadata';
import processFileMetadata from '@salesforce/apex/MuleSoftFileDownload.processFileMetadata';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const FIELDS = ['Account.MarinerExternalId__c',
    'Account.Loan_Number__c',
    'Account.SSN__c'
   ];

export default class AccountMetadataFetcher extends LightningElement {
    @api recordId;
    loanNumber = 'LN12345'; 
    ssn = '123-45-6789';     

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    wiredAccount({ error, data }) {
            console.log('Wired recordId1:', this.recordId);
                        console.log('Wired data:',data);


        if (data) {
            const marinerId = data.fields.MarinerExternalId__c?.value;
               this.loanNumber= data.fields.Loan_Number__c?.value;
             this.ssn = data.fields.SSN__c?.value;
             console.log('Wired MarinerExernalID__c  data.fields:',  data.fields);
            if (marinerId) {
                    console.log('Wired MarinerExernalID__c recordId');
               
                getFileMetadata({loanNumber:this.loanNumber,ssn:this.ssn}).then(jsonString=>{
                    this.fetchFileMetadata(jsonString);
                });
         

            } else {
                this.showToast('Info', 'MarinerExternalID__c is missing. No API call made.', 'info');
            }
        } else if (error) {
            this.showToast('Error', 'Failed to fetch Account data.', 'error');
        }
    }

    async fetchFileMetadata( jsonString) {
        try {
            await processFileMetadata({ accountId: this.recordId, jsonResponse:jsonString });
      
        } catch (error) {
            console.error(error);
            this.showToast('Error', error.body?.message || 'Error processing metadata.', 'error');
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}