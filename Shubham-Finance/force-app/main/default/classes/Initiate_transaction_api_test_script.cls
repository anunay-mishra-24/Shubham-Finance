public class Initiate_transaction_api_test_script implements Database.AllowsCallouts{
    
    public static void main(){
    
        Http http = new Http();
        HttpRequest req = new HttpRequest();
    
        /* ENDPOINT (from Postman) */
        req.setEndpoint('https://demo.perfios.com/KuberaVault/api/v3/organisations/shubhamHF/transactions');
        req.setMethod('POST');
        
        /* HEADERS  */
        req.setHeader('X-Perfios-Algorithm', 'PERFIOS-RSA-SHA256');
        req.setHeader(
            'X-Perfios-Content-Sha256',
            'a4cd572318d2142f49eded52752e4ae8c00949a8f014b27353fc82aefc8d5eab'
        );
        req.setHeader(
            'X-Perfios-Signature',
            '732fb55abbd97fc2ae9c1b4abbc8019d6692dce90bb55239b495ed183d089159a5ef203d68273d38286d1f7b5299e0b79960ad4246423307f549dc67ab025bf4e274fec545eceec7304713136228412f66bb97fa992527e8d7f558758481b7a0fe18d2f9dc76f81771bafc1896f3ffc7ae52bd25ad94b76a62982033d5065d2059d0730e39c9085781902590c7fd7cc6ea1d925ae05a669a274eae7a6d73a99174bd51461aa2a09d5fd75f41c8b0db2d0e05c3f7ebb228961900b13bead73af2b669eb877bc82958c7d54f0c3eb4f5acfc9878706331fd390d543fd9f99561fbe4225815bceaeca2e7f736d8f11a9fa2fbe29fb297b5ecbe9becb663b07ca5a17f94cb50dbd544ddab70b57ae7e5c27406190ca860c0aaac1dab316c52268844796bbbea2ad2142729b044c2f7fa38686cd35e7ec4d0a1d7799e3464e80fc36ba1bd72dd561ee7c8f9a643d823cd6400b8c2c0581e23a6c8011dcc55411a20903bad13cc57435d72d66d7f1475246923a8a8a2c38dd8d87d1e2fae8a1446a333b66d740a68e2fce6b9d72cf83130290025e57da787dbc32d4f330a3fcab07378a01f4828f0b570e05f68b511ab766622401b7f86fdf65c1522380368fa03fc02bf9c9ab02f345a4aeebd4f7798f9d765130252daf2c53a9d1b259658bcf935b4005fbfc510e33ae154a9f22efe7477fdd0ce6b9bffea8a794be95e0badc93697'
        );
        req.setHeader('X-Perfios-Signed-Headers', 'host;x-perfios-content-sha256;x-perfios-date');
        req.setHeader('X-Perfios-Date', '20191125T123214Z');
        req.setHeader('Host', 'demo.perfios.com');
        req.setHeader('Content-Type', 'application/json');
    
        /* BODY  */
        String requestBody =
        '<payload>' +
            '<txnId>Testing1234567</txnId>' +
            '<loanAmount>2000</loanAmount>' +
            '<loanDuration>6</loanDuration>' +
            '<loanType>Home</loanType>' +
            '<processingType>STATEMENT</processingType>' +
            '<transactionCompleteCallbackUrl>' +
                'https://staging-uat1.loanframe.com/internal/bank-statement/api/cancel-summary/loan/59d1c12b-fee2-415f-8cf9-34e076a75855?' +
            '</transactionCompleteCallbackUrl>' +
            '<proposedEmi>34555</proposedEmi>' +
            '<uploadingScannedStatements>false</uploadingScannedStatements>' +
            '<acceptancePolicy>atLeastOneTransactionInRange</acceptancePolicy>' +
            '<yearMonthFrom>2024-01</yearMonthFrom>' +
            '<autoDetectInstitution>true</autoDetectInstitution>' +
            '<yearMonthTo>2024-08</yearMonthTo>' +
            '<employmentType>Salaried</employmentType>' +
            '<employerName>TestingSSSSSSS</employerName>' +
        '</payload>';
    
        req.setBody(requestBody);
        
        /* SEND REQUEST*/
        HttpResponse res = http.send(req);
        
        System.debug('STATUS CODE ==> ' + res.getStatusCode());
        System.debug('STATUS       ==> ' + res.getStatus());
        System.debug('RESPONSE     ==> ' + res.getBody());

    }

}