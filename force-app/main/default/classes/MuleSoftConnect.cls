public with sharing class MuleSoftConnect {
    
    
    
    private static final String BASE_URL = 'https://sandbox-anypointapi.marinerfinance.com';
    private static final String CLIENT_ID = '5eb86e256e6e404bbc8475d5671afb3d';
    private static final String CLIENT_SECRET = 'd1732454042B427aa1701A565Eb2C8Ac';
    
    // ========== METHOD 1: Lookup Customer ==========
    public static String lookupCustomer(String email, String phone, String ssn) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/customer/lookup');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('clientID', CLIENT_ID);
        req.setHeader('clientSecret', CLIENT_SECRET);
        
        Map<String, Object> requestBody = new Map<String, Object>();
        if (email != null) requestBody.put('email', email);
        if (phone != null) requestBody.put('phone', phone);
        if (ssn != null) requestBody.put('ssn', ssn);
        
        req.setBody(JSON.serialize(requestBody));
        
        // Construct customer map
        Map<String, Object> addressMap = new Map<String, Object>{
            'street' => '123 Main St',
            'city' => 'New York',
            'state' => 'NY',
            'zipCode' => '12345'
        };
        
        
        Map<String, Object> customer = new Map<String, Object>{
            'firstName' => 'John',
            'lastName' => 'Doe',
            
            'dateOfBirth' => '1980-01-01',
            'guid' => '1234567890',
            'address' => addressMap
        };
        if(email!=null){
            customer.put('email', email);
        }
        else{
            customer.put('email', 'dummy@gmail.com');
        }
        
        
        if(phone!=null)
        {
            customer.put('phone',phone);
        }
        else{
            customer.put('phone','123456795');
        }
        if(ssn!=null)
        {
            customer.put('ssn',ssn);
        }
        else
        {
            customer.put('ssn','test1234');
        }
        
        
        
        Map<String, Object> response = new Map<String, Object>{
            'customers' => new List<Object>{ customer }
        };
        
        return JSON.serialize(response);
        
        /* try {
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                return res.getBody();
                
            } else {
                System.debug('API failed: ' + res.getStatusCode() + ' — returning mock data');
                return 'API failed';
            }
        } catch (Exception ex) {
            System.debug('Exception during lookupCustomer callout: ' + ex.getMessage());
            return 'Callout Exception';
        }    */
    }
    
    // ========== METHOD 1: Applications by email ==========
    public static String getApplicationsByEmail(String email) {
        
        if (String.isBlank(email)) {
            throw new IllegalArgumentException('Email is required');
        }
        
        
        
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(BASE_URL + '/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('clientID', CLIENT_ID);
        req.setHeader('clientSecret', CLIENT_SECRET);
        
        Map<String, Object> requestBody = new Map<String, Object>{
            'email' => email
        };
        
        req.setBody(JSON.serialize(requestBody));
        
        /* try {
            HttpResponse res = http.send(req);
            if (res.getStatusCode() == 200) {
                return res.getBody();
            } else {
                System.debug('API failed: ' + res.getStatusCode() + ' — returning mock data');
                return 'API failed';
            }
        } catch (Exception ex) {
            System.debug('Exception during getApplicationsByEmail callout: ' + ex.getMessage());
            return 'Exception Occure';
        }
         */
        
        
        
        
        
        //hardcoding response
        // Construct applicant note
        Map<String, Object> note = new Map<String, Object>{
            'type' => 'Note',
            'status' => 'Valid',
            'communicationType' => 'Email',
            'content' => 'This is a note.',
            'username' => 'jdoe@marinerfinance.com',
            'dateCreated' => '2023-10-01T12:00:00Z',
            'dateUpdated' => '2023-10-01T12:00:00Z',
            'title' => 'Application Note Title',
            'source' => 'applicant'
        };
        
        // Construct selected offer
        Map<String, Object> offer = new Map<String, Object>{
            'amount' => 1000,
            'term' => 12,
            'rate' => 5,
            'apr' => 5,
            'fee' => 100
        };
        
        // Construct applicant
        Map<String, Object> applicant = new Map<String, Object>{
            'customerGuid' => '1234567890',
            'appplicationGuid' => '0987654321',
            'applicantGuid' => '0987654321',
            'dateSubmitted' => '2023-10-01T12:00:00Z',
            'offerCode' => 'OFFER123',
            'ssn' => '123-45-6789',
            'promoCode' => 'PROMO123',
            'applicantNotes' => new List<Object>{ note },
            'verificationProgress' => new Map<String, Object>(),
            'status' => 'Pending',
            'branchNumber' => 123456,
            'branchName' => 'Main Branch',
            'selectedOffer' => offer
        };
        Map<String, Object> note1 = new Map<String, Object>{
            'type' => 'Note',
            'status' => 'Valid',
            'communicationType' => 'Email',
            'content' => 'This is a note.',
            'username' => 'jdoe@marinerfinance.com',
            'dateCreated' => '2023-10-01T12:00:00Z',
            'dateUpdated' => '2023-10-01T12:00:00Z',
            'title' => 'Application Note Title 1',
            'source' => 'applicant'
        };
        Map<String, Object> applicant1 = new Map<String, Object>{
            'customerGuid' => '1234567890',
            'appplicationGuid' => '0987654321',
            'applicantGuid' => '09876543839',
            'dateSubmitted' => '2023-10-01T12:00:00Z',
            'offerCode' => 'OFFER123',
            'ssn' => '123-45-6789',
            'promoCode' => 'PROMO123',
            'applicantNotes' => new List<Object>{ note1 },
            'verificationProgress' => new Map<String, Object>(),
            'status' => 'Pending',
            'branchNumber' => 123456,
            'branchName' => 'Main Branch',
            'selectedOffer' => offer
        };
        
        Map<String, Object> response = new Map<String, Object>{
            'applicants' => new List<Object>{ applicant,applicant1 }
        };
        
        return JSON.serialize(response);
    }
}