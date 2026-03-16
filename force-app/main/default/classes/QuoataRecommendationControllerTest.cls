@IsTest
private class QuoataRecommendationControllerTest {

    private class MockQuoataApi implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            if (req.getEndpoint().contains('/recommendations') && req.getMethod() == 'GET') {
                Map<String, Object> mockResponse = new Map<String, Object>();

                List<Map<String, Object>> recs = new List<Map<String, Object>>();
                Map<String, Object> rec1 = new Map<String, Object>();
                rec1.put('id', 'rec-001');
                rec1.put('type', 'new_assignment');
                rec1.put('icpScore', 96);
                rec1.put('reasoning', 'High ICP match, rep has capacity');
                rec1.put('detailLine', 'Currently unassigned');
                mockResponse.put('recommendations', recs);
                recs.add(rec1);

                mockResponse.put('recommendations', recs);
                mockResponse.put('totalCount', 1);

                Map<String, Object> summary = new Map<String, Object>();
                summary.put('currentBalance', 73);
                summary.put('projectedBalance', 91);
                summary.put('pipelineImpact', 2400000);
                summary.put('unassignedCount', 12);
                mockResponse.put('summary', summary);

                res.setBody(JSON.serialize(mockResponse));
            } else {
                res.setStatusCode(204);
                res.setBody('');
            }

            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account testAccount = new Account(Name = 'Test Corp', AnnualRevenue = 50000000);
        insert testAccount;
    }

    @IsTest
    static void testGetRecommendations() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi());

        Test.startTest();
        String result = QuoataRecommendationController.getRecommendations(
            UserInfo.getUserId(), 10
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a response');
        Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(1, ((List<Object>) parsed.get('recommendations')).size());
    }

    @IsTest
    static void testAcceptRecommendation() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi());

        Test.startTest();
        QuoataRecommendationController.acceptRecommendation('rec-001');
        Test.stopTest();
    }

    @IsTest
    static void testRejectRecommendation() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi());

        Test.startTest();
        QuoataRecommendationController.rejectRecommendation('rec-001');
        Test.stopTest();
    }

    @IsTest
    static void testSnoozeRecommendation() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi());

        Test.startTest();
        QuoataRecommendationController.snoozeRecommendation('rec-001');
        Test.stopTest();
    }

    @IsTest
    static void testAcceptAllRecommendations() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi());

        Test.startTest();
        QuoataRecommendationController.acceptAllRecommendations(
            new List<String>{ 'rec-001', 'rec-002' }
        );
        Test.stopTest();
    }
}

