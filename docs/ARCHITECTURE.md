# ARCHITECTURE.md
Cloudflare Email Manager Mobile – System Architecture

## High Level Architecture
Mobile App
  ↓
Cloudflare REST API
  ↓
Cloudflare GraphQL Analytics API

## Components
Mobile App
- Authentication with API Token
- Domain discovery
- Alias management
- Catch-all monitoring
- Activity analytics

Cloudflare REST API
- Domain discovery
- Email routing rules
- Destination email addresses

Cloudflare GraphQL API
- Email routing analytics
- Event logs

## Security
- Store API token using secure storage
- Android Keystore / iOS Keychain

## Performance
- Cache domains
- Cache alias list
- Pagination for activity logs