
@IsTest
private with sharing class SetPrimaryContactController_Test {
    private static Integer numberOfContacts = 5;
    private static Account testAccount;
    private static List<Contact> testContacts;
   
    private static void createTestData() {
        testContacts = new List<Contact>();
        testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        for (Integer i = 0; i < numberOfContacts; i++) {
            Contact newContact = new Contact(
                FirstName = 'Test',
                LastName = 'Name' + i,
                Phone = '444555666999',
                Is_Primary_Contact__c = false,
                AccountId = testAccount.Id
            );
            testContacts.add(newContact);
        }
        insert testContacts;
    }
    
    @IsTest
    private static void testSetPrimaryContact() {
        createTestData();
        Test.startTest();
        Apexpages.StandardController stdController = new Apexpages.StandardController(
            testAccount
        );
        SetPrimaryContactController testController = new SetPrimaryContactController(
            stdController
        );
        testController.contactId = testContacts.get(0).Id;
        testController.searchKey = '';
        testController.setPrimaryContact();
        testController.setPrimaryContact();
        Test.stopTest();

        System.assertEquals(
            1,
            [SELECT COUNT() FROM Contact WHERE Is_Primary_Contact__c = TRUE]
        );
        System.assert(testContacts.size() == numberOfContacts);
        System.assert(testAccount != null);
    }
   
    @IsTest
    private static void testRetrieveContacts() {
        Integer queryResultSize;
        createTestData();
        Test.startTest();
        Apexpages.StandardController stdController = new Apexpages.StandardController(
            testAccount
        );
        SetPrimaryContactController testController = new SetPrimaryContactController(
            stdController
        );
        testController.searchKey = 'Test';
        queryResultSize = testController.retrieveContacts('').size();
        testController.retrieveContacts('SELECT * FROM');
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Contact WHERE Is_Primary_Contact__c = TRUE]
        );
        System.assert(queryResultSize == testController.contacts.size());
        System.assert(testAccount != null);
    }
   
    @IsTest
    private static void testDoSearch() {
        createTestData();
        Test.startTest();
        Apexpages.StandardController stdController = new Apexpages.StandardController(
            testAccount
        );
        SetPrimaryContactController testController = new SetPrimaryContactController(
            stdController
        );
        testController.searchKey = 'Name1';
        testController.doSearch();
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Contact WHERE Is_Primary_Contact__c = TRUE]
        );
        System.assert(1 == testController.contacts.size());
        System.assert(testAccount != null);
    }
}