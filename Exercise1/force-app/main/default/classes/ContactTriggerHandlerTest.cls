
@isTest
private class ContactTriggerHandlerTest {

    @isTest
    static void testInsertPrimaryContact() {
        // Test verisi oluştur
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        Contact primaryContact = new Contact(
            LastName='Primary',
            AccountId=testAccount.Id,
            Is_Primary_Contact__c=true,
            Phone='1234567890'
        );

        // Birincil iletişim kişisini ekle
        Test.startTest();
        insert primaryContact;
        Test.stopTest();

        // Doğrulama
        Contact insertedContact = [SELECT Primary_Contact_Phone__c FROM Contact WHERE Id = :primaryContact.Id];
        System.assertEquals('1234567890', insertedContact.Primary_Contact_Phone__c, 'The primary contact phone should be set.');
    }

    @isTest static void testPreventMultiplePrimaryContactsForSameAccount() {
        // Test verisi oluştur
        Account testAccount = new Account(Name='Test Account');
        insert testAccount;

        Contact primaryContact = new Contact(
            LastName='Primary',
            AccountId=testAccount.Id,
            Is_Primary_Contact__c=true,
            Phone='1234567890'
        );
        insert primaryContact;

        Contact secondPrimaryContact = new Contact(
            LastName='Second Primary',
            AccountId=testAccount.Id,
            Is_Primary_Contact__c=true,
            Phone='0987654321'
        );

        // İkinci birincil iletişim kişisini eklemeye çalış
        Boolean exceptionThrown = false;
        try {
            insert secondPrimaryContact;
        } catch (DmlException e) {
            exceptionThrown = true;
        }

        // Doğrulama
        System.assert(exceptionThrown, 'An exception should be thrown when trying to insert a second primary contact for the same account.');
    }

    // Diğer test metodlarınızı burada tanımlayabilirsiniz...
}