public with sharing class ContactTriggerHandler {
    private static final String INSERT_CONTACTS_ERROR = 'The contact cannot be created because there is an already existing primary contact!';
    private static final String UPDATE_CONTACTS_ERROR = 'The contact cannot be updated because there is an already existing primary contact!';

    public void validatePrimaryBeforeInsert(List<Contact> contacts) {
        Map<Id, Integer> accountPrimaryCount = new Map<Id, Integer>();
        for (Contact con : contacts) {
            if (con.Is_Primary_Contact__c) {
                if (!accountPrimaryCount.containsKey(con.AccountId)) {
                    accountPrimaryCount.put(con.AccountId, 1);
                } else {
                    throw new ContactTriggerException(INSERT_CONTACTS_ERROR);
                }
            }
        }

        List<Contact> existingPrimaryContacts = [
            SELECT Id, AccountId
            FROM Contact
            WHERE AccountId IN :accountPrimaryCount.keySet() AND Is_Primary_Contact__c = true
        ];
        for (Contact con : existingPrimaryContacts) {
            if (accountPrimaryCount.containsKey(con.AccountId)) {
                throw new ContactTriggerException(INSERT_CONTACTS_ERROR);
            }
        }
    }

    public void validatePrimaryBeforeUpdate(List<Contact> newContacts, Map<Id, Contact> oldContactsMap) {
        for (Contact newCon : newContacts) {
            Contact oldCon = oldContactsMap.get(newCon.Id);
            if (newCon.Is_Primary_Contact__c != oldCon.Is_Primary_Contact__c && newCon.Is_Primary_Contact__c == true) {
                // Check if there's another primary contact for the same account
                Integer existingPrimaryCount = [
                    SELECT count()
                    FROM Contact
                    WHERE AccountId = :newCon.AccountId AND Is_Primary_Contact__c = true AND Id != :newCon.Id
                ];
                if (existingPrimaryCount > 0) {
                    throw new ContactTriggerException(UPDATE_CONTACTS_ERROR);
                }
            }
        }
    }

    public void processPrimaryAfterInsert(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact con : contacts) {
            if (con.Is_Primary_Contact__c) {
                accountIds.add(con.AccountId);
            }
        }
        updateContactsAsync(new List<Id>(accountIds));
    }

    public void processPrimaryAfterUpdate(List<Contact> contacts) {
        Set<Id> accountIds = new Set<Id>();
        for (Contact con : contacts) {
            if (con.Is_Primary_Contact__c) {
                accountIds.add(con.AccountId);
            }
        }
        updateContactsAsync(new List<Id>(accountIds));
    }

    @future
    private static void updateContactsAsync(List<Id> accountIds) {
        List<Contact> contactsToUpdate = new List<Contact>();
    for (Id accountId : accountIds) {
        // İlgili Account'un birincil iletişim kişisini bul
        Contact primaryContact = [
            SELECT Phone
            FROM Contact
            WHERE AccountId = :accountId AND Is_Primary_Contact__c = true
            LIMIT 1
        ].get(0);

        // Aynı Account'a ait diğer tüm iletişim kişilerini bul ve güncelle
        List<Contact> relatedContacts = [
            SELECT Id, Primary_Contact_Phone__c
            FROM Contact
            WHERE AccountId = :accountId AND Id != :primaryContact.Id
        ];
        
        for (Contact c : relatedContacts) {
            c.Primary_Contact_Phone__c = primaryContact.Phone;
            contactsToUpdate.add(c);
        }
    }
    
    if (!contactsToUpdate.isEmpty()) {
        try {
            // Partial success'i desteklemek için false kullan
            Database.update(contactsToUpdate, false);
        } catch (Exception e) {
            // Güncelleme sırasında bir hata oluşursa, uygun bir hata yönetimi stratejisi uygula
            // Örneğin, bir sistem log'una yaz
            System.debug('An error occurred while updating contacts: ' + e.getMessage());
            // Gerçek bir uygulamada, hataları loglamak ve takip etmek için daha sofistike yöntemler kullanılmalıdır.
        }
    }
    }
}