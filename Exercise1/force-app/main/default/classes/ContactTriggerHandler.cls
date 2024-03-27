public with sharing class ContactTriggerHandler {
    private static final String INSERT_CONTACTS_ERROR = 'The contact cannot be created because there is an already existing primary contact!';
    private static final String UPDATE_CONTACTS_ERROR = 'The contact cannot be updated because there is an already existing primary contact!';
    public void validatePrimaryBeforeInsert(List<Contact> con) {
        try {
            Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
            List<Id> accIds = new List<Id>();
            List<Contact> newPrimaryContacts = new List<Contact>();
            for (Contact c : con) {
                if (c.IsPrimaryContact__c) {
                    accIds.add(c.AccountId);
                    newPrimaryContacts.add(c);
                }
            }
            List<Contact> oldContact = findOldContacts(accIds, true);
            for (Contact c : oldContact) {
                primaryContacts.put(c.AccountId, c);
            }
            for (Contact c : newPrimaryContacts) {
                if (primaryContacts.containsKey(c.AccountId)) {
                    c.IsPrimaryContact__c.addError(INSERT_CONTACTS_ERROR);
                } else {
                    primaryContacts.put(c.AccountId, c);
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }

    private static List<Contact> findOldContacts(List<Id> accIds, Boolean isPrimary) {
        try {
            List<Contact> oldContact = [
                SELECT Id, Name, Is_Primary_Contact__c, AccountId
                FROM Contact
                WHERE
                    Is_Primary_Contact__c = :isPrimary
                    AND AccountId IN :accIds
            ];
            return oldContact;
        } catch (Exception e) {
            System.debug('Error: ' + e);
            return new List<Contact>();
        }
    }

    public void processPrimaryAfterInsert(List<Contact> con) {
        try {
            List<Id> conIds = new List<Id>();
            for (Contact c : con) {
                if (c.Is_Primary_Contact__c) {
                    conIds.add(c.Id);
                }
            }
            if (!System.IsBatch() && !System.isFuture()) {
                processPrimaryAfterInsertAndUpdateAsync(conIds);
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }

    @future
    private static void processPrimaryAfterInsertAndUpdateAsync(List<Id> conIds) {
        try {
            List<Contact> consToUpdate = new List<Contact>();
            List<Id> accIds = new List<Id>();
            Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
            List<Contact> insertedContacts = [
                SELECT
                    Primary_Contact_Phone__c,
                    Is_Primary_Contact__c,
                    AccountId,
                    Phone
                FROM Contact
                WHERE Id IN :conIds
            ];
            for (Contact c : insertedContacts) {
                accIds.add(c.AccountId);
                primaryContacts.put(c.AccountId, c);
            }

            List<Contact> oldContact = findOldContacts(accIds, false);
            for (Contact c : oldContact) {
                if (primaryContacts.containsKey(c.AccountId)) {
                    c.Primary_Contact_Phone__c = primaryContacts.get(c.AccountId).Phone;
                    consToUpdate.add(c);
                    if (!consToUpdate.contains(primaryContacts.get(c.AccountId))) {
                        primaryContacts.get(c.AccountId).Primary_Contact_Phone__c = primaryContacts.get(c.AccountId).Phone;
                        consToUpdate.add(primaryContacts.get(c.AccountId));
                    }
                }
            }

            Database.update(consToUpdate, false);
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }

    public void validatePrimaryBeforeUpdate(List<Contact> con, Map<Id, Contact> conOldMap) {
        try {
            Map<Id, Contact> primaryContacts = new Map<Id, Contact>();
            List<Contact> newPrimaryContacts = new List<Contact>();
            List<Id> accIds = new List<Id>();
            for (Contact c : con) {
                if (c.Is_Primary_Contact__c && !conOldMap.get(c.Id).Is_Primary_Contact__c) {
                    accIds.add(c.AccountId);
                    newPrimaryContacts.add(c);
                }
            }
            if (!accIds.isEmpty()) {
                List<Contact> oldContact = findOldContacts(accIds, true);
                for (Contact c : oldContact) {
                    primaryContacts.put(c.AccountId, c);
                }
                for (Contact c : newPrimaryContacts) {
                    if (primaryContacts.containsKey(c.AccountId)) {
                        c.Is_Primary_Contact__c.addError(UPDATE_CONTACTS_ERROR);
                    } else {
                        primaryContacts.put(c.AccountId, c);
                    }
                }
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }

    public void processPrimaryAfterUpdate(List<Contact> con) {
        try {
            List<Id> conIds = new List<Id>();
            for (Contact c : con) {
                if (c.Is_Primary_Contact__c == true) {
                    conIds.add(c.Id);
                }
            }
            if (!System.IsBatch() && !System.isFuture()) {
                processPrimaryAfterInsertAndUpdateAsync(conIds);
            }
        } catch (Exception e) {
            System.debug('Error: ' + e);
        }
    }
}