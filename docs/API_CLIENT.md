# API_CLIENT.md
Cloudflare API Client Design

## Base URLs
REST: https://api.cloudflare.com/client/v4
GraphQL: https://api.cloudflare.com/client/v4/graphql

## Authentication
Authorization: Bearer API_TOKEN

## List Domains
GET /zones

## List Email Routing Rules
GET /zones/{zone_id}/email/routing/rules

## Create Alias
POST /zones/{zone_id}/email/routing/rules

Example payload:
{
 "matchers":[{
  "type":"literal",
  "field":"to",
  "value":"alias@example.com"
 }],
 "actions":[{
  "type":"forward",
  "value":["destination@gmail.com"]
 }]
}

## Update Alias
PUT /zones/{zone_id}/email/routing/rules/{rule_id}

## Delete Alias
DELETE /zones/{zone_id}/email/routing/rules/{rule_id}

## Destination Email
GET /accounts/{account_id}/email/routing/addresses
POST /accounts/{account_id}/email/routing/addresses