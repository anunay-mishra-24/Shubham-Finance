@IsTest
private class SHF_ICICIInsuranceAPI_Helper_Test {

    private static Dom.Document buildSampleDocument() {
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('Response', null, null);

        Dom.XmlNode policy = root.addChildElement('PolicyNumber', null, null);
        policy.addTextNode('POL123');

        Dom.XmlNode premium = root.addChildElement('Premium', null, null);
        premium.addTextNode('1000');

        Dom.XmlNode premiumSummary1 = root.addChildElement('PremiumSummary', null, null);
        Dom.XmlNode gross = premiumSummary1.addChildElement('GrossPremium', null, null);
        gross.addTextNode('1500');
        Dom.XmlNode tax = premiumSummary1.addChildElement('Tax', null, null);
        tax.addTextNode('270');

        Dom.XmlNode premiumSummary2 = root.addChildElement('PremiumSummary', null, null);
        Dom.XmlNode discount = premiumSummary2.addChildElement('Discount', null, null);
        discount.addTextNode('50');

        return doc;
    }

    @IsTest
    static void testGetTagValue_directChild() {
        Test.startTest();
        Dom.Document doc = buildSampleDocument();
        Dom.XmlNode root = doc.getRootElement();

        String policy = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'PolicyNumber');
        String premium = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'Premium');

        System.assertEquals('POL123', policy, 'PolicyNumber should be returned for direct child');
        System.assertEquals('1000', premium, 'Premium should be returned for direct child');
        Test.stopTest();
    }

    @IsTest
    static void testGetTagValue_nestedInPremiumSummary() {
        Test.startTest();
        Dom.Document doc = buildSampleDocument();
        Dom.XmlNode root = doc.getRootElement();

        // Nested under PremiumSummary
        String grossPremium = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'GrossPremium');
        String tax = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'Tax');
        String discount = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'Discount');

        System.assertEquals('1500', grossPremium, 'Should find nested GrossPremium under PremiumSummary');
        System.assertEquals('270', tax, 'Should find nested Tax under PremiumSummary');
        System.assertEquals('50', discount, 'Should find nested Discount under PremiumSummary');
        Test.stopTest();
    }

    @IsTest
    static void testGetTagValue_missingTag() {
        Test.startTest();
        Dom.Document doc = buildSampleDocument();
        Dom.XmlNode root = doc.getRootElement();

        String notFound = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'NonExistentTag');
        System.assertEquals(null, notFound, 'Should return null if tag not present');
        Test.stopTest();
    }

    @IsTest
    static void testGetTagValue_invalidParams() {
        Test.startTest();
        // null parent
        String res1 = SHF_ICICIInsuranceAPI_Helper.getTagValue(null, 'Anything');
        System.assertEquals(null, res1, 'Null parent should return null');

        // blank tag
        Dom.Document doc = buildSampleDocument();
        Dom.XmlNode root = doc.getRootElement();
        String res2 = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, null);
        String res3 = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, '');
        String res4 = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, '   ');
        System.assertEquals(null, res2, 'Null tag should return null');
        System.assertEquals(null, res3, 'Empty tag should return null');
        System.assertEquals(null, res4, 'Whitespace tag should return null');
        Test.stopTest();
    }

    @IsTest
    static void testGetTagValue_defensiveTryCatch() {
        Test.startTest();
        Dom.Document doc = new Dom.Document();
        Dom.XmlNode root = doc.createRootElement('Root', null, null);
        // No children at all - loops should handle safely and return null for any search
        String value = SHF_ICICIInsuranceAPI_Helper.getTagValue(root, 'AnyTag');
        System.assertEquals(null, value, 'With no children present result should be null and no exception should bubble up');
        Test.stopTest();
    }
}