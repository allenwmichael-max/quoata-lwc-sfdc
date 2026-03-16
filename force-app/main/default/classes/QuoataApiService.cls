public with sharing class QuoataApiService {

    private static final String NAMED_CREDENTIAL = 'callout:Quoata_API';

    /**
     * Fetch recommendations for a specific manager from Quoata API.
     */
    @Future(callout=true)
    public static void warmRecommendationsCache(String managerId, Integer maxResults) {
        // Optional hook for future enhancements.
        getRecommendations(managerId, maxResults);
    }

    public static String getRecommendations(String managerId, Integer maxResults) {
        HttpRequest req = new HttpRequest();
        String endpoint = NAMED_CREDENTIAL + '/api/v1/recommendations'
            + '?managerId=' + EncodingUtil.urlEncode(managerId, 'UTF-8')
            + '&limit=' + String.valueOf(maxResults);
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            return res.getBody();
        }
        throw new QuoataApiException(
            'Quoata API returned status ' + res.getStatusCode() + ': ' + res.getBody()
        );
    }

    public static void acceptRecommendation(String recommendationId) {
        sendAction(recommendationId, 'accept');
    }

    public static void rejectRecommendation(String recommendationId) {
        sendAction(recommendationId, 'reject');
    }

    public static void snoozeRecommendation(String recommendationId) {
        sendAction(recommendationId, 'snooze');
    }

    public static void acceptAllRecommendations(List<String> recommendationIds) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/v1/recommendations/bulk-accept');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(30000);

        Map<String, Object> body = new Map<String, Object>();
        body.put('recommendationIds', recommendationIds);
        req.setBody(JSON.serialize(body));

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 204) {
            throw new QuoataApiException(
                'Quoata API bulk accept failed: ' + res.getStatusCode()
            );
        }
    }

    private static void sendAction(String recommendationId, String action) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + '/api/v1/recommendations/' + recommendationId + '/' + action);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setTimeout(15000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200 && res.getStatusCode() != 204) {
            throw new QuoataApiException(
                'Quoata API action failed: ' + res.getStatusCode()
            );
        }
    }

    public class QuoataApiException extends Exception {}
}

