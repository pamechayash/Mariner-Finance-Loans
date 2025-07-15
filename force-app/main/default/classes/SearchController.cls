public with sharing class SearchController {
    @AuraEnabled
    public static List<Account> searchAccounts(Map<String,String> searchData) {
        System.debug(searchData);
        List<String> conditions = new List<String>();
        
        String email='';
        String phone='';
        String ssn='';
        String offerCode='';
        String  zipCode='';
        String  city='';
        
        String checkNumber = '';
        if (searchData.containsKey('email') && String.isNotBlank(searchData.get('email'))) {
            email=searchData.get('email');
            conditions.add('Email__c = :email');
        }
        if (searchData.containsKey('phone') && String.isNotBlank(searchData.get('phone'))) {
            phone=searchData.get('phone');
            conditions.add('Phone = :phone');
        }
        if (searchData.containsKey('ssn') && String.isNotBlank(searchData.get('ssn'))) {
            ssn=searchData.get('ssn');
            conditions.add('SSN__c = :ssn');
        }
        
        
        if (searchData.containsKey('zip') && String.isNotBlank(searchData.get('zip'))) {
            zipCode=searchData.get('zip');
            conditions.add('BillingPostalCode = :zipCode');
        }
        if (searchData.containsKey('city') && String.isNotBlank(searchData.get('city'))) {
            city=searchData.get('city');
            conditions.add('BillingCity = :city');
        }
        if (conditions.isEmpty()) {
            return new List<Account>(); // no filters provided
        }
        
        String whereClause = String.join(conditions, ' OR ');
        String query = 'SELECT Id, Name, Phone, Email__c,BillingStreet,BillingCity,BillingState, SSN__c FROM Account WHERE ' + whereClause;
        system.debug('query'+query);
        return (List<Account>) Database.query(query);
    }
    @AuraEnabled
    public static  List<Map<String,Object>> externalSearchAccounts(String email, String phone, String ssn){
        String jsonResponse = MuleSoftConnect.lookupCustomer(email, phone, ssn);
        Map<String, Object> customersResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
        
        List<Map<String,Object>> customers = new  List<Map<String,Object>>();
        
        if(customersResponse.get('customers')!=null){
            List<Object> customersList =  (List<Object>) JSON.deserializeUntyped(Json.serialize(customersResponse.get('customers')));
            for(Object customer:customersList){
                Map<String,Object> customerMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(customer));
                customers.add(customerMap);
                
            }
            
        }
        System.debug('cust--'+customers);
        return customers;
        
    }
    @AuraEnabled
    public static  List<Map<String,Object>> externalSearchApplications(String email){
        
        try{
            String jsonResponse = MuleSoftConnect.getApplicationsByEmail(email);
            Map<String, Object> applicantsResponse = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            List<Map<String,Object>> applicants = new  List<Map<String,Object>>();
            
            if(applicantsResponse.get('applicants')!=null){
                List<Object> applicantsList =  (List<Object>) JSON.deserializeUntyped(Json.serialize(applicantsResponse.get('applicants')));
                for(Object applicant:applicantsList){
                    Map<String,Object> applicantMap = (Map<String,Object>) JSON.deserializeUntyped(JSON.serialize(applicant));
                    applicants.add(applicantMap);
                    
                }
            }
            
            return applicants;
            
            
        }
        catch(Exception e){
            System.debug('Error: ' + e.getMessage());
            return new List<Map<String,Object>>();
        }
        
        
        
        
    }
    
}