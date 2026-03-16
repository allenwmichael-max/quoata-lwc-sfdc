public with sharing class QuoataRecommendationController {

    /**
     * Get recommendations for the current manager.
     * Supports mock mode via Quoata_Config__mdt.Use_Mock_Data__c.
     */
    @AuraEnabled(cacheable=false)
    public static String getRecommendations(String managerId, Integer maxResults) {
        try {
            String apiResponse;

            if (useMockData()) {
                apiResponse = loadMockRecommendations();
            } else {
                apiResponse = QuoataApiService.getRecommendations(managerId, maxResults);
            }

            Map<String, Object> responseData =
                (Map<String, Object>) JSON.deserializeUntyped(apiResponse);
            List<Object> recs = (List<Object>) responseData.get('recommendations');

            if (recs == null) {
                return JSON.serialize(responseData);
            }

            Set<String> accountIds = new Set<String>();
            Set<String> userIds = new Set<String>();

            for (Object recObj : recs) {
                Map<String, Object> rec = (Map<String, Object>) recObj;
                if (rec.containsKey('accountId') && rec.get('accountId') != null) {
                    accountIds.add((String) rec.get('accountId'));
                }
                if (rec.containsKey('currentOwnerId') && rec.get('currentOwnerId') != null) {
                    userIds.add((String) rec.get('currentOwnerId'));
                }
                if (rec.containsKey('proposedOwnerId') && rec.get('proposedOwnerId') != null) {
                    userIds.add((String) rec.get('proposedOwnerId'));
                }
            }

            Map<Id, Account> accounts = new Map<Id, Account>();
            if (!accountIds.isEmpty()) {
                accounts = new Map<Id, Account>(
                    [
                        SELECT Id, Name, Owner.Name, Industry, AnnualRevenue
                        FROM Account
                        WHERE Id IN :accountIds
                    ]
                );
            }

            Map<Id, User> users = new Map<Id, User>();
            if (!userIds.isEmpty()) {
                users = new Map<Id, User>(
                    [
                        SELECT Id, Name
                        FROM User
                        WHERE Id IN :userIds
                    ]
                );
            }

            for (Object recObj : recs) {
                Map<String, Object> rec = (Map<String, Object>) recObj;
                String accId = (String) rec.get('accountId');
                String proposedId = (String) rec.get('proposedOwnerId');

                if (accId != null && accounts.containsKey((Id) accId)) {
                    Account acc = accounts.get((Id) accId);
                    rec.put('accountName', acc.Name);
                }
                if (proposedId != null && users.containsKey((Id) proposedId)) {
                    rec.put('proposedOwnerName', users.get((Id) proposedId).Name);
                }
            }

            return JSON.serialize(responseData);

        } catch (Exception e) {
            throw new AuraHandledException('Error loading recommendations: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void acceptRecommendation(String recommendationId) {
        try {
            QuoataApiService.acceptRecommendation(recommendationId);
        } catch (Exception e) {
            throw new AuraHandledException('Error accepting recommendation: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void rejectRecommendation(String recommendationId) {
        try {
            QuoataApiService.rejectRecommendation(recommendationId);
        } catch (Exception e) {
            throw new AuraHandledException('Error rejecting recommendation: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void snoozeRecommendation(String recommendationId) {
        try {
            QuoataApiService.snoozeRecommendation(recommendationId);
        } catch (Exception e) {
            throw new AuraHandledException('Error snoozing recommendation: ' + e.getMessage());
        }
    }

    @AuraEnabled
    public static void acceptAllRecommendations(List<String> recommendationIds) {
        try {
            QuoataApiService.acceptAllRecommendations(recommendationIds);
        } catch (Exception e) {
            throw new AuraHandledException('Error accepting all recommendations: ' + e.getMessage());
        }
    }

    private static Boolean useMockData() {
        try {
            Quoata_Config__mdt cfg = [
                SELECT Use_Mock_Data__c
                FROM Quoata_Config__mdt
                WHERE DeveloperName = 'Quoata_Config'
                LIMIT 1
            ];
            return cfg.Use_Mock_Data__c;
        } catch (Exception e) {
            return false;
        }
    }

    private static String loadMockRecommendations() {
        StaticResource res = [
            SELECT Body
            FROM StaticResource
            WHERE Name = 'Quoata_Mock_Recommendations'
            LIMIT 1
        ];
        Blob body = res.Body;
        return body.toString();
    }
}

