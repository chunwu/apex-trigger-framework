/**
 * Simply a superset of all trigger operations in relation to Account, organised in a top-level class.
 */
public inherited sharing class AccountTriggerOps {
    public class Validation implements TriggerOp {
        public Boolean isEnabled() {
            return Trigger.isInsert || Trigger.isUpdate;
        }
        
        public SObject[] filter() {
            return Trigger.new;
        }
        
        public void execute(Account[] accounts) {
            for (Account acc : accounts) {
                if (acc.Type == 'Prospect' && acc.Phone == null) {
                    acc.addError('When the Account Type is "Prospect", you must enter the Phone');
                }
                // Other field valiations
            }
        }
    }

    public class UpdateContactDescription implements TriggerOp {
        public Boolean isEnabled() {
            return Trigger.isUpdate;
        }
        
        public SObject[] filter() {
            Account[] result = new Account[] {};
            for (Account newAccount : (Account[]) Trigger.new) {
                Account oldAccount = (Account) Trigger.oldMap.get(newAccount.Id);
                if (oldAccount.NumberOfEmployees <= 50 && newAccount.NumberOfEmployees > 50)  {
                    result.add(newAccount);
                }
            }
            return result;
        }
        
        public void execute(Account[] accounts) {
            Id[] accountIds = new Id[] {};
            for (Account acc : accounts) {
                accountIds.add(acc.Id);
            }
            Contact[] contactsToUpdate = new Contact[] {};
            for (Account acc : [select Id, (select Description from Contacts) from Account where Id in :accountIds]) {
                for (Contact aContact : acc.Contacts) {
                    aContact.Description = 'Now the company size is increased';
                    contactsToUpdate.add(aContact);
                }
            }
            if (contactsToUpdate.size() > 0) update contactsToUpdate;
        }
    }
}
