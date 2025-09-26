# Mead Order App — ACA + Azure MySQL (cloud-only)

Deploy entirely in Azure via GitHub Actions + Bicep.

## Secrets
AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID, AZURE_CLIENT_ID, DOCKERHUB_USERNAME, DOCKERHUB_TOKEN, DB_ADMIN_USER, DB_ADMIN_PASSWORD

## Run
Use the workflow "Build and Deploy (ACA + MySQL)". Inputs: rg, location, imageTag.

## Notes
- MySQL Flexible Server username format: just `username` (no `@servername`).
- TLS enforced by default; container uses system CAs.
