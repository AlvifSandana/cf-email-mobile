# Cloudflare Email Manager Mobile

Mobile app berbasis Flutter untuk mengelola Cloudflare Email Routing langsung dari perangkat mobile menggunakan Cloudflare API Token.

## Ringkasan

Project ini ditujukan untuk mempermudah pengelolaan email alias pada domain yang dikelola di Cloudflare, tanpa perlu membangun mailbox sendiri. Aplikasi fokus pada pengalaman mobile-first untuk use case operasional harian seperti membuat alias, mengubah forwarding, memantau catch-all, dan melihat activity email routing.

## Tujuan Produk

- Login menggunakan Cloudflare API Token
- Menemukan domain Cloudflare secara otomatis
- Mengelola email alias: create, edit, delete, enable/disable
- Generate privacy alias dengan format acak
- Memantau catch-all usage
- Melihat activity log email routing

## Non-Goals

- Bukan SMTP server
- Bukan email sending client
- Bukan inbox/email reader

## High-Level Architecture

```text
Mobile App
  ↓
Cloudflare REST API
  ↓
Cloudflare GraphQL Analytics API
```

## Authentication

Autentikasi menggunakan `Authorization: Bearer API_TOKEN`.

Permission minimum yang dibutuhkan:

- Zone:Read
- Email Routing Rules:Read
- Email Routing Rules:Edit
- Email Routing Addresses:Read
- Email Routing Addresses:Edit

## Fitur Utama

### MVP

- Login with API token
- Domain selector
- Alias CRUD
- Alias generator
- Catch-all monitor
- Activity logs

### Future / Production Expansion

- Destination email manager
- Disposable alias dengan TTL
- Bulk alias import
- Alias analytics
- Spam detection
- Worker integration
- Multi-destination forwarding

## Struktur Aplikasi

Mengikuti Flutter Clean Architecture:

```text
lib/
 ├ core/
 │   ├ config/
 │   ├ constants/
 │   ├ network/
 │   └ utils/
 │
 ├ features/
 │   ├ auth/
 │   ├ domains/
 │   ├ aliases/
 │   ├ catchall/
 │   └ analytics/
 │
 ├ shared/
 │   ├ widgets/
 │   ├ themes/
 │   └ models/
 │
 └ main.dart
```

Layer utama:

- Presentation → UI
- Domain → business logic
- Data → repositories dan API integration
- Core → shared utilities dan network foundation

## Navigasi Utama

Bottom navigation direncanakan berisi:

- Dashboard
- Aliases
- Catch-All
- Activity
- Settings

## API Overview

Base URL:

- REST: `https://api.cloudflare.com/client/v4`
- GraphQL: `https://api.cloudflare.com/client/v4/graphql`

Endpoint utama:

- `GET /zones`
- `GET /zones/{zone_id}/email/routing/rules`
- `POST /zones/{zone_id}/email/routing/rules`
- `PUT /zones/{zone_id}/email/routing/rules/{rule_id}`
- `DELETE /zones/{zone_id}/email/routing/rules/{rule_id}`
- `GET /accounts/{account_id}/email/routing/addresses`
- `POST /accounts/{account_id}/email/routing/addresses`

## Dokumentasi Project

Seluruh referensi awal tersedia di folder [`docs/`](./docs):

- `PRD.md` — kebutuhan produk dan scope
- `ARCHITECTURE.md` — arsitektur sistem tingkat tinggi
- `API_CLIENT.md` — rancangan API client Cloudflare
- `FLUTTER_STRUCTURE.md` — struktur folder dan layer Flutter
- `ROADMAP.md` — rencana implementasi 14 hari
- `UI_WIREFRAME.md` — wireframe flow layar utama
- `IMPLEMENTATION_PLAN.md` — rencana implementasi MVP dan production-ready (source of truth eksekusi)

## Status Saat Ini

Repository ini saat ini berada pada tahap perencanaan dan dokumentasi awal. Langkah berikutnya adalah menyiapkan project Flutter, fondasi network/auth, lalu membangun flow vertikal MVP mulai dari authentication hingga alias management.
