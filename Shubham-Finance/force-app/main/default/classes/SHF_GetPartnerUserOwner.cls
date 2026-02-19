public class SHF_GetPartnerUserOwner {

    public class Input {
        @InvocableVariable
        public Id accountId;
    }

    public class Output {
        @InvocableVariable
        public Id userId;
    }

    @InvocableMethod(label='Get Partner User by Account')
    public static List<Output> getOwnerUser(List<Input> inputs) {
        List<Output> results = new List<Output>();
        System.debug('==== GetPartnerUserOwner invoked ====');
        System.debug('Inputs received: ' + inputs);

        if (inputs != null && !inputs.isEmpty()) {
            Id accountId = inputs[0].accountId;
            System.debug('Account Id from input: ' + accountId);

            // First find Contact(s) related to this Account
            List<Id> contactIds = new List<Id>();
            for (Contact c : [SELECT Id FROM Contact WHERE AccountId = :accountId
            ]) {
                contactIds.add(c.Id);
            }

            System.debug('Contact Ids found: ' + contactIds);

            // Now find Users with those ContactIds
            if (!contactIds.isEmpty()) {
                List<User> users = [SELECT Id FROM User WHERE ContactId IN :contactIds ORDER BY CreatedDate ASC LIMIT 1];

                System.debug('Users found: ' + users);

                if (!users.isEmpty()) {
                    Output o = new Output();
                    o.userId = users[0].Id;
                    results.add(o);
                    System.debug('Selected User Id: ' + o.userId);
                } else {
                    System.debug('No User found for Contacts of this Account');
                }
            } else {
                System.debug('No Contacts found for Account');
            }
        } else {
            System.debug('Input list is null or empty.');
        }

        System.debug('Final Output: ' + results);
        return results;
    }
}