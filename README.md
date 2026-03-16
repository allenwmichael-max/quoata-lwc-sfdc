# Quoata Territory Recommendations LWC

This Salesforce DX project contains the **Quoata territory recommendations** Lightning Web Component and supporting Apex services for embedding Quoata’s territory optimization directly on Salesforce Home, App, and Record Pages.

## Structure

- **force-app/main/default/lwc/**
  - `quoataRecommendations` – main container component shown on the Home page.
  - `quoataRecommendationCard` – individual recommendation card.
  - `quoataSummaryBar` – territory health summary bar.
- **force-app/main/default/classes/**
  - `QuoataApiService` – Apex service for Quoata HTTP callouts.
  - `QuoataRecommendationController` – Apex controller used by the LWC.
  - `QuoataApiServiceTest`, `QuoataRecommendationControllerTest` – test coverage.
- **force-app/main/default/remoteSiteSettings/**
  - `QuoataAPI` – remote site setting for `https://api.quoata.io` (optional when using Named Credentials).
- **force-app/main/default/customMetadata/**
  - `Quoata_Config__mdt` record with a `Use_Mock_Data__c` flag for mock mode.
- **force-app/main/default/staticresources/**
  - `Quoata_Mock_Recommendations` – sample JSON used when mock mode is enabled.

## Deployment

1. Authenticate to your Dev Hub:

   ```bash
   sf org login web --set-default-dev-hub --alias devhub
   ```

2. Create a scratch org:

   ```bash
   sf org create scratch --definition-file config/project-scratch-def.json --alias quoata-dev --duration-days 30 --set-default
   ```

3. Deploy:

   ```bash
   sf project deploy start --target-org quoata-dev
   ```

4. Open the org and add the **Quoata territory recommendations** component to a Home Page using Lightning App Builder.

## Mock Mode

The controller checks the `Quoata_Config__mdt` custom metadata record. When `Use_Mock_Data__c` is `true`, it returns data from the `Quoata_Mock_Recommendations` static resource instead of calling the live Quoata API. This allows developing and demoing the LWC without an external dependency.

