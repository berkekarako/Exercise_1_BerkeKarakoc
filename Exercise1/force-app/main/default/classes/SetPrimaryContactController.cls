
public with sharing class SetPrimaryContactController {
	public static final String RETRIEVE_CONTACTS_ERROR = 'An error occurred while retrieving contacts!';
	public static final String UPDATE_CONTACT_ERROR = 'An error occurred while updating the contact!';
	public String searchKey { get; set; }
	public String contactId { get; set; }
	public List<Contact> contacts { get; set; }

	private final Id accountId;


	public SetPrimaryContactController(ApexPages.StandardController controller) {
		this.accountId = controller.getId();
		this.contacts = this.retrieveContacts('');
	}

	
	public void setPrimaryContact() {
		try {
			List<Contact> existingPrimaryContacts = this.retrieveContacts('Is_Primary_Contact__c = TRUE');
			for (Contact existingPrimaryContact : existingPrimaryContacts) {
				existingPrimaryContact.Is_Primary_Contact__c = false;
			}
			//we add our new primary contact
			existingPrimaryContacts.add(new Contact(Id = this.contactId, Is_Primary_Contact__c = true));

			update existingPrimaryContacts;

			this.contacts = this.retrieveContacts('');
		} catch (Exception e) {
			System.debug('Error: ' + e);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, UPDATE_CONTACT_ERROR));
		}
	}

	
	public void doSearch() {
		this.contacts = this.retrieveContacts('');
	}

	
    @TestVisible
	private List<Contact> retrieveContacts(String additionalWhereConditions) {
		String query = 'SELECT Id, Name, Is_Primary_Contact__c, Phone, Title ' + ' FROM Contact' + ' WHERE Account.Id = :accountId';
		if (String.isNotBlank(this.searchKey)) {
			query += ' AND Name LIKE \'%' + String.escapeSingleQuotes(searchKey) + '%\'';
		}
		if (String.isNotBlank(additionalWhereConditions)) {
			query += ' AND ' + additionalWhereConditions;
		}
		query += ' LIMIT 1000';

		try {
			return Database.query(query);
		} catch (QueryException e) {
			System.debug('Error: ' + e);
			ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, RETRIEVE_CONTACTS_ERROR));
			return new List<Contact>();
		}
	}
}