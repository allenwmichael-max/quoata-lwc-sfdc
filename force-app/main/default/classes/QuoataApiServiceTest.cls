@IsTest
private class QuoataApiServiceTest {

    private class MockQuoataApi implements HttpCalloutMock {
        private Integer statusCode;

        MockQuoataApi(Integer statusCode) {
            this.statusCode = statusCode;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(this.statusCode);

            if (this.statusCode == 200) {
                res.setBody('{"recommendations":[],"totalCount":0,"summary":{}}');
            } else {
                res.setBody('{"error":"Test error"}');
            }
            return res;
        }
    }

    @IsTest
    static void testGetRecommendationsSuccess() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi(200));

        Test.startTest();
        String result = QuoataApiService.getRecommendations(UserInfo.getUserId(), 10);
        Test.stopTest();

        System.assertNotEquals(null, result);
    }

    @IsTest
    static void testGetRecommendationsError() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi(500));

        Test.startTest();
        try {
            QuoataApiService.getRecommendations(UserInfo.getUserId(), 10);
            System.assert(false, 'Should have thrown exception');
        } catch (QuoataApiService.QuoataApiException e) {
            System.assert(e.getMessage().contains('500'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testAcceptRecommendation() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi(204));

        Test.startTest();
        QuoataApiService.acceptRecommendation('rec-001');
        Test.stopTest();
    }

    @IsTest
    static void testRejectRecommendation() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi(204));

        Test.startTest();
        QuoataApiService.rejectRecommendation('rec-001');
        Test.stopTest();
    }

    @IsTest
    static void testSnoozeRecommendation() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi(204));

        Test.startTest();
        QuoataApiService.snoozeRecommendation('rec-001');
        Test.stopTest();
    }

    @IsTest
    static void testAcceptAllRecommendations() {
        Test.setMock(HttpCalloutMock.class, new MockQuoataApi(200));

        Test.startTest();
        QuoataApiService.acceptAllRecommendations(new List<String>{ 'rec-001' });
        Test.stopTest();
    }
}

