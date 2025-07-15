import { LightningElement, track } from 'lwc';
import searchAccounts from '@salesforce/apex/SearchController.searchAccounts';
import externalSearchAccounts from '@salesforce/apex/SearchController.externalSearchAccounts';
import externalSearchApplications from '@salesforce/apex/SearchController.externalSearchApplications';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import BillingAddress from '@salesforce/schema/Account.BillingAddress';
export default class  MerinerOnlineApplicationSearch extends LightningElement {

    currentPage = 1;
    pageSize = 10;
    totalPages = 0;
    accountResults = [];

    @track pageSlice = [];
    Email = null;
    Phone = null;
    dataIdsToHide = [];
    SSN = null;
    isUp = true;
    isDown = false;
    noApp = false;
    up = 'chevronup';
    down = 'chevrondown';
    pageTitle = 'Online Applications';
    description = 'Enter a customer’s email ,phone number, or SSN (at least one is required unless using an Offer Code or Check Number).You may also optionally include address, city, state, or ZIP to help retrieve the online application.';
    customersList = [];
    CheckNumber = null;
    //isApplicationPage=false;
    isCustomerSearchPage = true;

    showCustomers = false;
    ZipCode = '';
    City = '';
    OfferCode = null;
    @track accounts = [];
    @track showTable = false;
    inputFields = [
        'Email', 'Phone', 'SSN', 'Zip Code', 'City', 'Check Number', 'Offer Code'
    ];



    handleChange(event) {
        let field = event.target.name;
        if (field.includes(' ')) {
            field = field.replace(' ', '');
        }
        console.log('field' + field);
        this[field] = event.target.value;
    }
    columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Email', fieldName: 'Email__c' },
        { label: 'Phone', fieldName: 'Phone' },
        { label: 'SSN', fieldName: 'SSN__c' },
        { label: 'Birth Date', fieldName: 'DateOfBirth' },
        { label: 'Address', fieldName: 'BillingAddress' },
        { label: 'recordLink', fieldName: 'recordLink', type: 'url' },

    ];
    showExternalCall = false;

    applicationsColumns = [
        { label: 'Type', fieldName: 'type' },
        { label: 'Notes', fieldName: 'notes' },
        { label: 'Username', fieldName: 'username' },
        { label: 'Created Date', fieldName: 'createdDate', type: 'date' },
        { label: 'Date Updated', fieldName: 'updatedDate', type: 'date' },
        { label: 'Title', fieldName: 'title' },
        { label: 'Source', fieldName: 'source' },
        { label: 'Verification Progress', fieldName: 'verificationProgress' },
        { label: 'Status', fieldName: 'status' },
        { label: 'Branch Number', fieldName: 'branchNumber' },
        { label: 'Branch Name', fieldName: 'branchName' },
        { label: 'Amount/Term/Rate/APR/Fee', fieldName: 'loanInfo' }
    ];

    @track applications = [
    ];

    async handleSearch() {

        if ((this.Email != null || this.Phone != null || this.SSN != null)) {

            let result = await searchAccounts({ searchData: { email: this.Email, phone: this.Phone, ssn: this.SSN, city: this.City, zip: this.ZipCode } })

            result = result.map(cust => ({
                ...cust,
                BillingAddress: cust.BillingStreet + ' ' + cust.BillingCity + ' ' + cust.BillingState,
                recordLink: '/lightning/r/ObjectAPIName/' + cust.Id + '/view',
                keyUp: cust.Id + 'Up',
                keyDown: cust.Id + 'Down',
                keyApp: cust.Id + 'App'
            }));

            this.accountResults = result;
            if (this.accountResults.length != 0) {
                this.totalPages = Math.ceil(result.length / this.pageSize);
                if (this.accountResults.length < this.pageSize) {
                    this.pageSize = this.accountResults.length;

                }
                await this.setPageData();
            }

            if (this.accountResults.length == 0) {
                this.handleExternalSearch();
                this.showExternalCall = false;
            }
            else {
                this.showExternalCall = true;
            }
            this.isCustomerSearchPage = false;
            this.showCustomers = true;
            this.description = 'Here are customers we found based on your search.';
            this.pageTitle = 'Customer Search';

        }
        else {
            const event = new ShowToastEvent({
                title: 'Error :',
                message: 'Please select at least one of Email, Phone, or SSN, unless you are using an Offer Code or Check Number.',
                variant: 'error'
            });
            this.dispatchEvent(event);

        }
    }
    async handleNext() {
        if (this.currentPage < this.totalPages) {
            this.currentPage++;
            await this.setPageData();
        }
    }
    get isPrevDisabled() {
        return this.currentPage === 1;
    }
    get isNextDisabled() {
        return this.currentPage === this.totalPages;
    }
    async handlePrevious() {
        if (this.currentPage > 1) {
            this.currentPage--;
            await this.setPageData();
        }
    }

    async setPageData() {
        console.log('this.currentPage' + this.currentPage);

        const start = (this.currentPage - 1) * this.pageSize;
        const end = start + this.pageSize;



        for (let i = start; i < end; i++) {
            console.log('this.accountResults.length' + this.accountResults.length);
            console.log('i' + i);
            if (this.accountResults.length < i) {
                break;
            }

            let applicants = await externalSearchApplications({ 'email': this.accountResults[i].Email__c });

            let applicationList = [];


            for (let i = 0; i < applicants.length; i++) {
                let applicant = applicants[i];

                let applicantObject = {
                    Id: i,
                    status: applicant.status,
                    branchNumber: applicant.branchNumber,
                    branchName: applicant.branchName,
                    loanInfo: 'Dummy data',
                    verificationProgress: applicant.verificationProgress
                };
                console.log('applicantObject' + applicantObject);

                if (applicant.applicantNotes != null && applicant.applicantNotes.length > 0) {
                    applicantObject.type = applicant.applicantNotes[0].type;
                    applicantObject.notes = applicant.applicantNotes[0].content;
                    applicantObject.username = applicant.applicantNotes[0].username;

                    applicantObject.createdDate = applicant.applicantNotes[0].dateCreated;

                    applicantObject.updatedDate = applicant.applicantNotes[0].dateUpdated;
                    applicantObject.title = applicant.applicantNotes[0].title;
                    applicantObject.source = applicant.applicantNotes[0].source;



                }


                applicationList.push(applicantObject);

            }

            console.log('applicationList' + applicationList);

            this.applications = applicationList;

            if (applicationList.length == 0) {
                this.isCustomerSearchPage = false;
                this.showCustomers = true;
                let dataId = this.accountResults[i].Id;
                this.dataIdsToHide.push(dataId);

            }

            this.accountResults[i].applications = applicationList;
            console.log('applicants' + JSON.stringify(this.accountResults[i].applications));

        }

        this.pageSlice = this.accountResults.slice(start, end);
        console.log('this.pageSlice--' + JSON.stringify(this.pageSlice));
    }

    async handleExternalSearch() {

        if ((this.Email != null || this.Phone != null || this.SSN != null)) {
            let customers = await externalSearchAccounts({ 'email': this.Email, 'phone': this.Phone, 'ssn': this.SSN });

            for (let i = 0; i < customers.length; i++) {
                let customer = customers[i];
                let customerObject = {
                    Id: i,
                    Name: customer.firstName + ' ' + customer.lastName,
                    Phone: customer.phone,
                    Email__c: customer.email,
                    SSN__c: customer.ssn,
                    BillingAddress: customer.address.street + ' ' + customer.address.city + ' ' + customer.address.state,
                    DateOfBirth: customer.dateOfBirth
                };
                this.customersList.push(customerObject);
            }

            this.customersList = this.customersList.map(cust => ({
                ...cust,
                keyUp: cust.Id + 'Up',
                keyDown: cust.Id + 'Down',
                keyApp: cust.Id + 'App'
            }));





            this.accountResults = this.customersList;



            if (this.accountResults.length != 0) {
                this.totalPages = Math.ceil(this.customersList.length / this.pageSize);
                if (this.accountResults.length < this.pageSize) {
                    this.pageSize = this.accountResults.length;

                }
                await this.setPageData();
            }

            this.showTable = this.accountResults.length > 0;


        } else {

            const event = new ShowToastEvent({
                title: 'Error :',
                message: 'Please select at least one of Email, Phone, or SSN, unless you are using an Offer Code or Check Number.',
                variant: 'error'
            });
            this.dispatchEvent(event);
        }
    }

    handleUpClick(event) {
        const dataId = event.currentTarget.dataset.id;
        const email = event.currentTarget.dataset.key;
        console.log('Email' + email);
        let upKey = dataId + 'Up';
        let downKey = dataId + 'Down';

        let up = this.template.querySelector(`[data-id="${upKey}"]`);
        let down = this.template.querySelectorAll(`[data-id="${downKey}"]`);
        if (down[0].style.display == 'block' && down[1].style.display == 'block') {
            up.style.display = 'block';
            down[0].style.display = 'none';
            down[1].style.display = 'none';
        }
        else {
            up.style.display = 'none';
            down[0].style.display = 'block';
            down[1].style.display = 'block';
        }
    }

    renderedCallback() {
        for (let i = 0; i < this.dataIdsToHide.length; i++) {
            let element = this.template.querySelector(`[data-id="${this.dataIdsToHide[i]}"]`);
            let element1 = this.template.querySelector(`[data-key="${this.dataIdsToHide[i]}"]`)
            if (element != null) {
                element.textContent = 'No Applications';
            }
            if (element1 != null) {
                element1.style.display = 'none';
            }
        }
    }
}