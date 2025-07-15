global class DocumentChecklistPurgeBatch implements Database.Batchable<SObject>, Schedulable {
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        // Query all checklist items with the target status
        return Database.getQueryLocator([
            SELECT Id
            FROM DocumentChecklistItem
            WHERE Status = 'File Services - Temporary'
        ]);
    }
    
    global void execute(Database.BatchableContext bc, List<DocumentChecklistItem> scope) {
        Set<Id> checklistIds = new Set<Id>();
        for (DocumentChecklistItem item : scope) {
            checklistIds.add(item.Id);
        }
        
        // Query all ContentDocumentLinks for these checklist items
        Map<Id, Set<Id>> checklistToDocIds = new Map<Id, Set<Id>>();
        Set<Id> allDocIds = new Set<Id>();
        for (ContentDocumentLink cdl : [
            SELECT ContentDocumentId, LinkedEntityId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :checklistIds
        ]) {
            if (!checklistToDocIds.containsKey(cdl.LinkedEntityId)) {
                checklistToDocIds.put(cdl.LinkedEntityId, new Set<Id>());
            }
            checklistToDocIds.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
            allDocIds.add(cdl.ContentDocumentId);
        }
        
        // Delete the ContentDocuments (cascades to all versions/links)
        if (!allDocIds.isEmpty()) {
            List<ContentDocument> docsToDelete = [
                SELECT Id FROM ContentDocument WHERE Id IN :allDocIds
            ];
            delete docsToDelete;
        }
        
        // Update checklist item statuses
        List<DocumentChecklistItem> toUpdate = new List<DocumentChecklistItem>();
        for (DocumentChecklistItem item : scope) {
            item.Status = 'Purged - File Services';
            toUpdate.add(item);
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    global void finish(Database.BatchableContext bc) {
        // Optional: logging or notification
    }
    
    // Schedulable support
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new DocumentChecklistPurgeBatch(), 200);
    }
}