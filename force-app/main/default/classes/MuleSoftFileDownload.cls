public class MuleSoftFileDownload {
        private static final String CLIENT_ID = 's21cujvp5y99ns2ohirjadcxq6yp8588';
        private static final String CLIENT_SECRET = 'DYXvTUTJig9tDdhxfBY1Bybrq67zJZu4';
        
        // box api access token
        private static final String ACCESS_TOKEN = '4bbap2a7V3A8opDkzL9kkJ8ZxI21FpC8';
        
        @AuraEnabled
        public static String downloadAndAttachFile(String fileId, Id parentRecordId) {
            if (String.isEmpty(fileId) || parentRecordId == null) {
                throw new AuraHandledException('File ID or Parent Record ID is missing.');
            }
            
            DocumentChecklistItem checklistItem = [
            SELECT Id, Document_Link__c, LastDownloadDate__c
            FROM DocumentChecklistItem
            WHERE Id = :parentRecordId
            LIMIT 1
        ];
            
            
            String fileName = fetchFileNameFromBox(fileId);
            if (String.isEmpty(fileName)) {
                throw new AuraHandledException('Could not fetch file name from Box.');
            }
            
            Blob fileContent = downloadBoxFile(fileId);
            if (fileContent == null) {
                throw new AuraHandledException('Failed to download file content.');
            }
            
            Id contentDocumentId = saveFileToSalesforce(fileContent, fileName);
            linkFileToRecord(contentDocumentId, parentRecordId);
            
            String fileUrl = '/sfc/servlet.shepherd/document/download/' + contentDocumentId;
            
            checklistItem.Document_Link__c = fileUrl;
            checklistItem.LastDownloadDate__c = Date.today();
            //checklistItem.Status = 'File Services - Temporary';
            update checklistItem;
            
            return fileUrl;
        }
        //calling box api for testing
        private static String fetchFileNameFromBox(String fileId) {
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://api.box.com/2.0/files/' + fileId);
            request.setMethod('GET');
            request.setHeader('Authorization', 'Bearer ' + ACCESS_TOKEN);
            
            HttpResponse response = http.send(request);
            
            if (response.getStatusCode() == 200) {
                Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
                return (String) jsonResponse.get('name');
            } else {
                System.debug('Failed to fetch file name. Status: ' + response.getStatusCode());
            }
            return null;
        }
        
        private static String fetchFileFromMule(String loanNumber) {
            // Map<String, String> headers = new Map<String, String>();
            // headers.put('Content-Type', 'application/json');
            // headers.put('x-user-id', UserInfo.getUserId());
            // headers.put('x-employee-number', '456');
        // HttpResponse res = AnyPointPaymentsGateway.AbstractFilesConsumer('{"fileId": "1","loanNumber": "' + loanNumber + '"}', headers);
        
        // System.debug(res.getStatusCode());
        // System.debug(res.getStatus());
        return null;
    }
    
    
    
    private static Blob downloadBoxFile(String fileId) {
        Http http = new Http();
        HttpRequest req = new HttpRequest();
        req.setEndpoint('https://api.box.com/2.0/files/' + fileId + '/content');
        req.setMethod('GET');
        req.setHeader('Authorization', 'Bearer ' + ACCESS_TOKEN);
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() == 200) {
            return res.getBodyAsBlob();
        } else if (res.getStatusCode() == 302) {
            String redirectUrl = res.getHeader('location');
            if (!String.isEmpty(redirectUrl)) {
                HttpRequest redirectReq = new HttpRequest();
                redirectReq.setEndpoint(redirectUrl);
                redirectReq.setMethod('GET');
                HttpResponse redirectRes = http.send(redirectReq);
                
                if (redirectRes.getStatusCode() == 200) {
                    return redirectRes.getBodyAsBlob();
                }
            }
        }
        return null;
    }
    
    private static Id saveFileToSalesforce(Blob fileBody, String fileName) {
        ContentVersion cv = new ContentVersion();
        cv.VersionData = fileBody;
        cv.PathOnClient = fileName;
        insert cv;
        
        ContentVersion insertedCV = [
            SELECT ContentDocumentId
            FROM ContentVersion
            WHERE Id = :cv.Id
            LIMIT 1
        ];
        return insertedCV.ContentDocumentId;
    }
    
    private static void linkFileToRecord(Id contentDocumentId, Id parentRecordId) {
        List<ContentDocumentLink> existingLinks = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE ContentDocumentId = :contentDocumentId
            AND LinkedEntityId = :parentRecordId
            LIMIT 1
        ];
        
        if (existingLinks.isEmpty()) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = contentDocumentId;
            cdl.LinkedEntityId = parentRecordId;
            cdl.ShareType = 'V';
            insert cdl;
        }
    }
    
    
    @AuraEnabled
    public static String getFileMetadata(String loanNumber, String ssn) {
        System.debug('loanNumber' + loanNumber);
        System.debug('ssn' + ssn);
        String jsonResponse = '{"files":[' +
            '{"fileId":"1923980091902","name":"file.txt","dateUploaded":"2023-10-01T12:00:00Z","fileSize":1024,"compressedFileSize":512,"dateDropped":"2023-10-01T12:00:00Z","fileDescriptorId":1,"lastUpdated":"2023-10-01T12:00:00Z","userName":"Mule API"}' +
            '],"status":{"statusCode":"Success","statusMessage":"Success"}}';
        
        return jsonResponse;
    }
    
    @AuraEnabled
    public static void processFileMetadata(String accountId,String jsonResponse) {
        System.debug('accountId=>'+accountId);
        try {
            
            System.debug('jsonResponse=>'+jsonResponse);
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(jsonResponse);
            Map<String, Object> statusMap = (Map<String, Object>) responseMap.get('status');
            System.debug('statusMap=>'+statusMap );
            if (statusMap.get('statusCode') == 'Success') {
                List<Object> files = (List<Object>) responseMap.get('files');
                List<DocumentChecklistItem> checklistItems = new List<DocumentChecklistItem>();
                
                for (Object fileObj : files) {
                    Map<String, Object> fileMap = (Map<String, Object>) fileObj;
                    
                    DocumentChecklistItem item = new DocumentChecklistItem();
                    item.ParentRecordId = accountId;
                    item.MarinerExternalID__c = String.valueOf(fileMap.get('fileId'));
                    item.Name = String.valueOf(fileMap.get('name'));
                    item.File_Size__c = (Integer) fileMap.get('fileSize');
                    item.Compressed_File_Size__c = (Integer) fileMap.get('compressedFileSize');
                    item.Date_Uploaded__c = DateTime.valueOf(((String) fileMap.get('dateUploaded')).replace('T', ' ').replace('Z', ''));
                    item.Date_Dropped__c = DateTime.valueOf(((String) fileMap.get('dateDropped')).replace('T', ' ').replace('Z', ''));
                    // item.Last_Updated__c = DateTime.valueOf((String) fileMap.get('lastUpdated')).date();
                    item.User_Name__c = String.valueOf(fileMap.get('userName'));
                    item.File_Descriptor_Id__c = String.valueOf(fileMap.get('fileDescriptorId'));
                    
                    checklistItems.add(item);
                }
                
                if (!checklistItems.isEmpty()) {
                    upsert checklistItems MarinerExternalID__c;
                }
            }
            
        } catch (Exception e) {
            System.debug('Error processing file metadata: ' + e.getMessage());
            throw new AuraHandledException('Error processing file metadata: ' + e.getMessage());
        }
    }
}