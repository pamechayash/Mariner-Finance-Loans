import { LightningElement ,api,wire,track} from 'lwc';
import externalSearchApplications from '@salesforce/apex/SearchController.externalSearchApplications';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import ACCOUNT_NAME_FIELD from '@salesforce/schema/Account.Name';
import ACCOUNT_EMAIL_FIELD from '@salesforce/schema/Account.Email__c';
import ACCOUNT_PHONE_FIELD from '@salesforce/schema/Account.Phone';
 export default class AccountApplicationsRelatedList extends LightningElement {
    @api recordId;
        countBool=true;
        titleWithCount='Applications (0)';
        accountName;
    accountEmail;
     isOpen = false;
    accountPhone;
    allApplicants;
    @track selectedApp={};
        @track applications=[];
        @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_NAME_FIELD, ACCOUNT_EMAIL_FIELD, ACCOUNT_PHONE_FIELD] })
        wiredAccount({ error, data }) {
            if (data) {
                this.accountName = getFieldValue(data, ACCOUNT_NAME_FIELD);
                this.accountEmail = getFieldValue(data, ACCOUNT_EMAIL_FIELD);
                this.accountPhone = getFieldValue(data, ACCOUNT_PHONE_FIELD);
                externalSearchApplications({'email':this.accountEmail}).then(applicants=>{
          
                    if(applicants.length==0){
                        this.countBool=false;
                     this.titleWithCount='Applications (0)';
                    }
                    else{
                        let applicationList=[];
                         this.titleWithCount='Applications ('+applicants.length+')';
               
                         for (let i = 0; i < applicants.length; i++) {
                          
                            let applicant = applicants[i];
                          
                            let applicantObject =  {
                                Id: i,
                                ssn: applicant.ssn,
                                status: applicant.status,
                                dateSubmitted: applicant.dateSubmitted,
                                promoCode:  applicant.promoCode,
                                branchNumber: applicant.branchNumber,
                                branchName:applicant.branchName,
                                loanInfo: 'Dummy data',
                                verificationProgress: applicant.verificationProgress
                            };
                            this.allApplicants = applicants;
            
                            if(applicant.applicantNotes!=null && applicant.applicantNotes.length>0){
                                applicantObject.type= applicant.applicantNotes[0].type;
                                applicantObject.notes= applicant.applicantNotes[0].content;
                                applicantObject.username= applicant.applicantNotes[0].username;
                             
                                applicantObject.createdDate= applicant.applicantNotes[0].dateCreated;
            
                                applicantObject.updatedDate= applicant.applicantNotes[0].dateUpdated;
                                applicantObject.title= applicant.applicantNotes[0].title;
                                applicantObject.source= applicant.applicantNotes[0].source;
                            }
                            if(applicant.selectedOffer!=null){
                                applicantObject.amount= applicant.selectedOffer.amount;
                                applicantObject.term= applicant.selectedOffer.term;
                                applicantObject.fee= applicant.selectedOffer.fee;
                                applicantObject.rate= applicant.selectedOffer.apr;
                                applicantObject.apr= applicant.selectedOffer.rate;
                            }  
                        applicationList.push(applicantObject);
                            
                        }
                        this.applications=  applicationList;
                       this.top3= this.applications.slice(0, 3);

                    }
    
            });

            } else if (error) {
                console.error('Error loading account data', error);
            }
        }

        handleTitleClick(event){
            const dataId = event.currentTarget.dataset.id;
            this.isOpen=true;
           this.selectedApp= this.applications[dataId];     
        }

        closeModal() {
            this.isOpen = false;
            const closeEvent = new CustomEvent('close');
            this.dispatchEvent(closeEvent);
        }


}