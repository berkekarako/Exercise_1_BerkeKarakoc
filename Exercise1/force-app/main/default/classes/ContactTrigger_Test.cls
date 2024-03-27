
@isTest
public with sharing class ContactTrigger_Test {
    private static Integer numberOfContacts = 5;
    private static Account testAccount;
    
    private static void init(String actionToInit) {
        switch on actionToInit {
            when 'scenario1' {
                List<Contact> testContacts = new List<Contact>();
                testAccount = new Account(Name = 'Test Account');
                insert testAccount;
                for (Integer i = 0; i < numberOfContacts; i++) {
                    Contact newContact = new Contact(
                        FirstName = 'Test',
                        LastName = 'Name' + i,
                        Phone = '444555666999' +
                            Integer.valueof((Math.random() * 1000)),
                        Is_Primary_Contact__c = false,
                        AccountId = testAccount.Id
                    );
                    testContacts.add(newContact);
                }
                insert testContacts;
            }
            when 'scenario2' {
                List<Contact> testContacts = new List<Contact>();
                testAccount = new Account(Name = 'Test Account');
                insert testAccount;
                for (Integer i = 0; i < numberOfContacts; i++) {
                    Boolean isPrimary = false;
                    if (i > 3) {
                        isPrimary = true;
                    }
                    Contact newContact = new Contact(
                        FirstName = 'Test',
                        LastName = 'Name' + i,
                        Phone = '444555666999' +
                            Integer.valueof((Math.random() * 1000)),
                        Is_Primary_Contact__c = isPrimary,
                        AccountId = testAccount.Id
                    );
                    testContacts.add(newContact);
                }
                insert testContacts;
            }
        }
    }
 
    @IsTest
    private static void testInsertContactScenario1() {
        init('scenario1');
        List<Contact> newContacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            Boolean isPrimary = false;
            String conPhone =
                '444555666999' + Integer.valueof((Math.random() * 1000));
            if (i > 0) {
                isPrimary = true;
                conPhone = '000888';
            }
            Contact newContact = new Contact(
                FirstName = 'Test',
                LastName = 'LastName' + i,
                Phone = conPhone,
                Is_Primary_Contact__c = isPrimary,
                AccountId = testAccount.Id
            );
            newContacts.add(newContact);
        }
        Test.startTest();
        Database.SaveResult[] srList = Database.insert(newContacts, false);
        Test.stopTest();
        for (Contact c : [SELECT Primary_Contact_Phone__c FROM Contact]) {
            System.assertEquals('000888', c.Primary_Contact_Phone__c);
        }
        System.assertEquals(7, [SELECT COUNT() FROM Contact]);
        System.assert(srList[2].getErrors() != null);
    }
  
    @IsTest
    private static void testInsertContactScenario2() {
        init('scenario2');
        List<Contact> newContacts = new List<Contact>();
        for (Integer i = 0; i < 3; i++) {
            Boolean isPrimary = false;
            String conPhone =
                '444555666999' + Integer.valueof((Math.random() * 1000));
            if (i == 0) {
                isPrimary = true;
                conPhone = '000888';
            }
            Contact newContact = new Contact(
                FirstName = 'Test',
                LastName = 'LastName' + i,
                Phone = conPhone,
                Is_Primary_Contact__c = isPrimary,
                AccountId = testAccount.Id
            );
            newContacts.add(newContact);
        }
        Test.startTest();
        Database.SaveResult[] srList = Database.insert(newContacts, false);
        Test.stopTest();
        System.assertEquals(7, [SELECT COUNT() FROM Contact]);
        System.assert(srList[0].getErrors() != null);
    }
 
    @IsTest
    private static void testUpdateContactScenario1() {
        init('scenario1');
        List<Contact> updateContacts = new List<Contact>();
        Integer counter = 0;
        for (Contact c : [SELECT Is_Primary_Contact__c, Id FROM Contact]) {
            if (counter < 2) {
                c.Is_Primary_Contact__c = true;
                updateContacts.add(c);
            }
            counter++;
        }

        Test.startTest();
        Database.SaveResult[] srList = Database.update(updateContacts, false);
        Test.stopTest();
        System.assertEquals(5, [SELECT COUNT() FROM Contact]);
        System.assert(srList[1].getErrors() != null);
        String primaryContactPhone = [
            SELECT Phone
            FROM Contact
            WHERE Id = :srList[0].getId()
        ]
        .Phone;
        for (Contact c : [
            SELECT Primary_Contact_Phone__c
            FROM Contact
        ]) {
            System.assertEquals(
                primaryContactPhone,
                c.Primary_Contact_Phone__c
            );
        }
    }
  
    @IsTest
    private static void testUpdateContactScenario2() {
        init('scenario2');
        Contact c = [
            SELECT Is_Primary_Contact__c
            FROM Contact
            WHERE Is_Primary_Contact__c = FALSE
            LIMIT 1
        ];

        c.Is_Primary_Contact__c = true;

        Test.startTest();
        Database.SaveResult sr = Database.update(c, false);
        Test.stopTest();
        System.assertEquals(5, [SELECT COUNT() FROM Contact]);
        System.assert(sr.getErrors() != null);
    }
}