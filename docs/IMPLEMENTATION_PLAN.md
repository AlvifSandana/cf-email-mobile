# Implementation Plan — Cloudflare Email Manager Mobile

## Overview

Cloudflare Email Manager Mobile adalah aplikasi Flutter untuk mengelola Cloudflare Email Routing langsung dari perangkat mobile menggunakan API Token Cloudflare. Berdasarkan PRD dan dokumen arsitektur, implementasi dibagi menjadi dua track: **MVP** untuk validasi fitur inti secepat mungkin, dan **Production-Ready** untuk hardening, observability, reliability, serta kesiapan rilis.

---

## Tujuan

### MVP
- Memungkinkan user login dengan Cloudflare API Token
- Menemukan domain secara otomatis dari akun Cloudflare
- Mengelola alias email dasar: list, create, edit, delete, enable/disable
- Menyediakan alias generator
- Menampilkan catch-all monitor dan activity logs dasar
- Merilis app yang usable untuk satu user/device dengan alur utama lengkap

### Production-Ready
- Meningkatkan keamanan penyimpanan token dan session handling
- Menambahkan kualitas UX, error handling, loading/empty/offline states
- Memperkuat data layer, pagination, caching, dan retry behavior
- Menambah observability, QA automation, dan release readiness
- Menyiapkan fondasi untuk scaling fitur lanjutan seperti analytics, bulk actions, dan multi-destination

---

## Asumsi

- Aplikasi Flutter menggunakan pendekatan **Clean Architecture** sesuai `docs/FLUTTER_STRUCTURE.md`
- Base API mengikuti:
  - REST: `https://api.cloudflare.com/client/v4`
  - GraphQL: `https://api.cloudflare.com/client/v4/graphql`
- Autentikasi hanya menggunakan **Bearer API Token**, tanpa OAuth
- User memilih satu domain aktif pada satu waktu
- Data utama yang perlu dikelola:
  - Domain
  - Alias/routing rules
  - Destination email
  - Activity log
- Catch-all monitor pada MVP kemungkinan berbasis aktivitas/log, bukan engine rules kompleks
- Activity log memakai GraphQL analytics API, minimal dengan pagination/infinite scroll
- Secure storage menggunakan Android Keystore / iOS Keychain

---

## Scope Summary

### MVP Scope
- Auth dengan API token
- Domain discovery + domain selector
- Alias CRUD
- Alias generator
- Catch-all monitor sederhana
- Activity logs dasar
- Bottom navigation: Dashboard, Aliases, Catch-All, Activity, Settings

### Production-Ready Scope
- Secure token lifecycle yang lebih matang
- Caching domain & alias list
- Pagination + pull-to-refresh
- Error mapping per endpoint
- Empty/loading/error/offline state di semua layar
- Logging & diagnostics
- Automated tests, CI checks, release config
- Performance optimization dan polish UI

---

## Architecture Focus

Struktur implementasi mengikuti pembagian berikut:

- `lib/core/`
  - `config/`: environment, app config
  - `constants/`: route names, API paths, string constants
  - `network/`: HTTP client, auth header injection, GraphQL client, interceptors/error mapper
  - `utils/`: generator, validators, date formatting, result wrapper

- `lib/features/auth/`
  - Login screen
  - Token validation
  - Secure storage access
  - Session state

- `lib/features/domains/`
  - Domain fetching
  - Domain selector
  - Selected zone/account context

- `lib/features/aliases/`
  - Alias list
  - Alias CRUD
  - Alias generator
  - Enable/disable alias
  - Destination email selector/input

- `lib/features/catchall/`
  - Catch-all activity list
  - Create alias from detected address
  - Ignore/block actions placeholder atau lightweight implementation

- `lib/features/analytics/`
  - GraphQL analytics query
  - Activity log list
  - Pagination/filter ringan

- `lib/shared/`
  - Reusable widgets, themes, models

---

# Track 1: MVP Plan

## Phase 1 — Foundation & Project Setup
**Goal:** menyiapkan fondasi proyek agar feature delivery berikutnya cepat dan konsisten.

### Deliverables
- Flutter project initialized dengan folder structure sesuai dokumen
- Dependency baseline:
  - HTTP client
  - State management
  - Secure storage
  - JSON serialization
  - Routing/navigation
- App theme dasar, bottom navigation shell, route map
- Core utilities:
  - `ApiResult` / `Failure` abstraction
  - Form validators
  - Loading/error state base widgets

### Implementasi konkret
- `lib/main.dart`
- `lib/core/config/`
- `lib/core/constants/`
- `lib/core/network/`
- `lib/shared/themes/`
- `lib/shared/widgets/`

### Catatan
Mulai dari shell app lebih dulu agar setiap feature berikutnya langsung bisa dipasang dan diuji di UI flow nyata.

---

## Phase 2 — Authentication & Secure Token Storage
**Goal:** user dapat login dengan API Token dan token tersimpan aman.

### Deliverables
- Login screen sesuai wireframe
- Token input validation
- Simpan token ke secure storage
- Inject `Authorization: Bearer <token>` ke semua request
- Logout flow
- Basic auth failure handling:
  - token kosong
  - token invalid
  - permission tidak cukup

### Implementasi konkret
- `lib/features/auth/presentation/login_page.dart`
- `lib/features/auth/data/auth_repository_impl.dart`
- `lib/features/auth/domain/`
- `lib/core/network/rest_client.dart`
- `lib/core/network/graphql_client.dart`

### Quality gate
- Login dengan token valid membawa user ke domain selector/dashboard
- Token invalid memunculkan error message yang jelas
- Logout menghapus token dari storage

---

## Phase 3 — Domain Discovery & App Context
**Goal:** app mengetahui domain mana yang akan dikelola user.

### Deliverables
- Integrasi `GET /zones`
- Domain list screen
- Persist selected domain/zone
- Dashboard header menampilkan domain aktif
- Fallback jika user tidak punya zone

### Implementasi konkret
- `lib/features/domains/data/`
- `lib/features/domains/domain/`
- `lib/features/domains/presentation/domain_selector_page.dart`
- `lib/shared/models/domain_model.dart`

### Quality gate
- Domain berhasil dimuat dari API
- User bisa memilih domain
- State domain aktif tersedia untuk feature aliases, catch-all, analytics

---

## Phase 4 — Alias Management Core
**Goal:** menyelesaikan use case utama: lihat dan kelola alias.

### Deliverables
- Alias list screen
- Create alias form
- Edit alias form
- Delete alias action
- Enable/disable alias
- Refresh alias list setelah mutation
- Validasi field:
  - alias kosong
  - destination kosong
  - format email invalid

### Endpoint terkait
- `GET /zones/{zone_id}/email/routing/rules`
- `POST /zones/{zone_id}/email/routing/rules`
- `PUT /zones/{zone_id}/email/routing/rules/{rule_id}`
- `DELETE /zones/{zone_id}/email/routing/rules/{rule_id}`

### Implementasi konkret
- `lib/features/aliases/data/datasources/alias_remote_datasource.dart`
- `lib/features/aliases/data/repositories/alias_repository_impl.dart`
- `lib/features/aliases/domain/usecases/`
- `lib/features/aliases/presentation/pages/alias_list_page.dart`
- `lib/features/aliases/presentation/pages/create_alias_page.dart`
- `lib/features/aliases/presentation/pages/edit_alias_page.dart`
- `lib/shared/models/alias_model.dart`

### Quality gate
- User bisa create/edit/delete alias dari mobile tanpa restart app
- Alias list konsisten setelah perubahan
- Error API ditampilkan per aksi, bukan generic crash

---

## Phase 5 — Alias Generator
**Goal:** mempercepat pembuatan alias privacy-style.

**Status:** ✅ Selesai

### Deliverables
- Alias generator UI
- Generator format `service-random@domain.com`
- Tombol regenerate
- Langsung create alias dari hasil generator

### Implementasi konkret
- `lib/features/aliases/presentation/pages/alias_generator_page.dart`
- `lib/core/utils/alias_generator.dart`

### Quality gate
- Format alias sesuai PRD
- Hasil generate tidak kosong dan relatif unik
- Create alias dari generated value berjalan end-to-end

### Catatan implementasi
- Generator diimplementasikan sebagai **page baru** dari Alias List
- Submit memakai alias yang sedang dipreview user, bukan regenerate ulang saat create
- Session invalidation tetap konsisten dengan flow alias lain:
  - hanya `invalidToken` dan `insufficientPermissions` yang force logout
  - network/recoverable failure tetap stay in flow

---

## Phase 6 — Catch-All Monitor Sederhana
**Goal:** memberi visibility terhadap alamat yang tertangkap catch-all.

**Status:** 🚧 In Progress

### Deliverables
- Catch-all monitor screen
- Daftar alamat hasil deteksi dari log/activity
- Action:
  - Create Alias
  - Ignore
  - Block (boleh MVP sebagai placeholder state/UI jika backend policy belum penuh)
- Reuse data dari analytics bila memungkinkan untuk menghindari duplikasi integrasi

### Implementasi konkret
- `lib/features/catchall/data/`
- `lib/features/catchall/domain/`
- `lib/features/catchall/presentation/pages/catchall_page.dart`

### Catatan risiko
Bagian “block” berisiko ambigu jika belum ada endpoint/rule model yang jelas. Untuk MVP, aman jika diposisikan sebagai:
- UI action dengan local state, atau
- create/update rule strategy yang sederhana jika sudah didefinisikan

### Quality gate
- Address yang tidak dikenali bisa diubah menjadi alias baru
- Empty state tersedia saat belum ada data catch-all

### Progress saat ini
- Catch-All tab sudah diganti dari placeholder menjadi page nyata
- Sudah ada model/repository contract minimal untuk detected addresses
- Sudah ada state loading/error/empty/list pada Catch-All page
- Sudah ada aksi:
  - Create Alias (reuse create alias flow dengan prefill local part)
  - Ignore (local UI state)
  - Block (placeholder UI eksplisit)
- Widget tests untuk flow dasar Catch-All sudah ditambahkan dan hijau

### Catatan lanjutan
- Phase ini **belum ditandai selesai** karena app runtime masih memakai `EmptyCatchAllRepository`
- Agar benar-benar memenuhi vertical slice Phase 6, perlu data source nyata untuk daftar alamat hasil deteksi dari log/activity

---

## Phase 7 — Activity Logs via GraphQL
**Goal:** menampilkan aktivitas email routing dasar.

### Deliverables
- GraphQL client
- Query analytics logs
- Activity log list screen
- Tampilan minimal:
  - email address
  - status
  - SPF
  - DKIM
  - DMARC
  - timestamp
- Basic pagination/load more

### Implementasi konkret
- `lib/features/analytics/data/datasources/analytics_remote_datasource.dart`
- `lib/features/analytics/data/repositories/analytics_repository_impl.dart`
- `lib/features/analytics/domain/usecases/get_activity_logs.dart`
- `lib/features/analytics/presentation/pages/activity_logs_page.dart`
- `lib/shared/models/activity_log_model.dart`

### Quality gate
- Log tampil untuk domain aktif
- Error GraphQL ter-handle rapi
- Pagination dasar berfungsi tanpa duplicate entries

---

## Phase 8 — MVP Polish & Internal Release
**Goal:** menutup gap UX dan menyiapkan demo/release awal.

### Deliverables
- Dashboard ringkas
- Bottom navigation final
- Loading/error/empty state di semua layar utama
- Basic settings screen:
  - token info
  - logout
  - refresh action
- README internal / test checklist

### Quality gate
- Happy path lengkap:
  login → pilih domain → list alias → create/edit/delete → generate alias → lihat activity
- Tidak ada blocker crash pada flow utama
- Siap dipakai internal/beta

---

# Track 2: Production-Ready Plan

## Phase 1 — Security Hardening
**Goal:** memastikan token dan data sensitif aman.

### Deliverables
- Secure storage abstraction yang teruji
- Token masking di UI dan logs
- Optional token validation step saat login
- Permission error mapping yang spesifik
- Session expiration / forced relogin handling bila token gagal

### Tambahan implementasi
- `lib/features/auth/domain/entities/auth_failure.dart`
- `lib/core/network/auth_interceptor.dart`
- `lib/core/utils/redaction.dart`

---

## Phase 2 — Data Reliability & Performance
**Goal:** memperkuat pengalaman penggunaan harian.

### Deliverables
- Cache domain list
- Cache alias list per zone
- Pull-to-refresh di list utama
- Debounce pada form submit
- Request retry ringan untuk network failure tertentu
- Pagination yang stabil untuk activity logs

### Tambahan implementasi
- Local cache layer ringan di repository
- Stale-while-refresh behavior untuk domain dan aliases

---

## Phase 3 — UX Completion
**Goal:** membuat aplikasi terasa matang dan konsisten.

### Deliverables
- Dashboard yang lebih informatif:
  - total aliases
  - catch-all status
  - emails today
  - recent activity
- Verified destination email manager
- Empty states yang jelas dan actionable
- Confirmation dialogs untuk destructive actions
- Form helper text & validation messages yang konsisten
- Dark mode / theming refinement

### Endpoint tambahan
- `GET /accounts/{account_id}/email/routing/addresses`
- `POST /accounts/{account_id}/email/routing/addresses`

---

## Phase 4 — Observability & Diagnostics
**Goal:** memudahkan debugging dan support.

### Deliverables
- Centralized logger
- API error categorization:
  - unauthorized
  - forbidden
  - validation error
  - rate limit
  - server error
  - network timeout
- Optional debug screen / API log viewer di Settings
- Crash reporting integration bila diperlukan

---

## Phase 5 — Automated Quality & Release Engineering
**Goal:** memastikan perubahan aman dan siap distribusi.

### Deliverables
- Unit tests untuk domain logic dan utilities
- Widget tests untuk layar utama
- Integration tests untuk happy path penting
- Linting, formatting, static analysis
- CI pipeline:
  - `flutter analyze`
  - `flutter test`
  - build validation
- Build flavor / config untuk dev dan prod

---

## Phase 6 — Release Readiness & Future-Feature Foundation
**Goal:** menutup gap sebelum public launch dan membuka jalan untuk roadmap berikutnya.

### Deliverables
- App icon, splash, package metadata
- Privacy note terkait API token usage
- Better settings:
  - refresh interval
  - debug toggle
- Struktur extensible untuk fitur masa depan:
  - disposable alias TTL
  - bulk alias import
  - spam detection
  - worker integration
  - multi-destination forwarding

---

## Testing & Quality Gates

### MVP Quality Gates
- **Unit tests**
  - alias generator
  - email validator
  - auth token storage wrapper
  - repository response mapping
- **Widget tests**
  - login screen
  - domain selector
  - alias list
  - create/edit alias form
  - activity list state
- **Integration tests**
  - login → select domain → create alias
  - edit alias → toggle enabled → delete alias
  - generate alias → create alias
- **Manual QA checklist**
  - invalid token
  - no domains available
  - empty alias list
  - network offline
  - API timeout
  - GraphQL error response

### Production-Ready Quality Gates
- `flutter analyze` tanpa issue kritis
- Test pass rate stabil untuk core flows
- Tidak ada token yang terekspos di logs/UI
- P95 loading time list utama acceptable pada koneksi mobile normal
- Crash-free session target internal terpenuhi
- Semua destructive action memiliki confirmation + recovery UX yang jelas

---

## Risiko Utama & Mitigasi

### 1. Ambiguitas implementasi Catch-All “Ignore” dan “Block”
- **Risiko:** PRD menyebut aksi, tetapi detail endpoint/rule logic belum lengkap
- **Mitigasi:** pada MVP, fokus ke “Create Alias” + “Ignore” sebagai state/UI ringan; definisikan “Block” secara eksplisit sebelum production

### 2. API Token permission tidak lengkap
- **Risiko:** user login berhasil tetapi sebagian fitur gagal
- **Mitigasi:** validasi permission secara eksplisit setelah login dan tampilkan daftar permission yang dibutuhkan

### 3. Mapping Cloudflare routing rules ke model alias mobile
- **Risiko:** struktur rule lebih fleksibel daripada kebutuhan UI sederhana
- **Mitigasi:** batasi MVP hanya pada pola rule `literal to -> forward single destination`; tandai rule unsupported secara aman

### 4. GraphQL analytics complexity
- **Risiko:** query sulit distabilkan, schema bisa berubah, pagination membingungkan
- **Mitigasi:** mulai dari query minimal dengan model data sempit; jangan gabungkan analytics dengan feature lain pada fase awal

### 5. Penyimpanan token sensitif
- **Risiko:** security issue jika token bocor ke logs atau local storage biasa
- **Mitigasi:** wajib gunakan secure storage, redact token, dan hindari persistence di debug logs

### 6. UX rapuh saat network lambat/gagal
- **Risiko:** app terasa tidak stabil
- **Mitigasi:** loading state, retry action, cached last-known data, dan pesan error yang spesifik

---

## Rekomendasi Urutan Eksekusi

### Urutan paling efisien
1. **Foundation**
2. **Authentication**
3. **Domain Discovery**
4. **Alias List**
5. **Create Alias**
6. **Edit/Delete/Enable-Disable Alias**
7. **Alias Generator**
8. **Activity Logs**
9. **Catch-All Monitor**
10. **Dashboard & Settings**
11. **MVP QA / internal release**
12. **Security hardening**
13. **Caching & pagination**
14. **Destination email manager**
15. **Observability**
16. **Automated tests + CI**
17. **Release polish**

### Alasan urutan ini
- Alias management adalah core value dan paling cepat memvalidasi use case utama
- Analytics dan catch-all bergantung pada domain/auth context yang sudah stabil
- Catch-all sebaiknya setelah analytics karena kemungkinan besar berbagi sumber data
- Hardening, observability, dan automation ditaruh setelah happy path stabil agar effort tidak terbuang pada API contract yang masih berubah

---

## Milestone Ringkas

### Milestone A — Functional MVP
- Login berhasil
- Domain selector berjalan
- Alias CRUD lengkap
- Alias generator aktif
- Activity logs dasar tampil
- Catch-all monitor sederhana tersedia

### Milestone B — Beta Internal
- Dashboard dan settings usable
- Error handling cukup jelas
- QA checklist lulus untuk flow utama
- Tidak ada crash blocker

### Milestone C — Production-Ready
- Security hardening selesai
- Cache/pagination/retry stabil
- Test automation & CI aktif
- UX polished
- Siap distribusi beta/public

---

## Success Criteria

### MVP
- [ ] User dapat login dengan API token yang valid
- [ ] User dapat memilih domain aktif
- [ ] User dapat melihat, membuat, mengedit, menghapus, dan toggle alias
- [ ] User dapat generate alias dan langsung menyimpannya
- [ ] User dapat melihat activity log email
- [ ] User dapat melakukan aksi dasar dari catch-all monitor
- [ ] Flow utama berjalan tanpa crash blocker

### Production-Ready
- [ ] Token tersimpan aman dan tidak terekspos
- [ ] Error handling konsisten di seluruh layar
- [ ] Domain, aliases, dan activity logs memiliki state loading/empty/error yang baik
- [ ] Test automation melindungi flow kritikal
- [ ] App stabil pada koneksi mobile biasa
- [ ] Struktur kode siap dikembangkan ke fitur roadmap berikutnya

---

## Final Recommendation

Strategi terbaik adalah **menyelesaikan MVP secara vertikal per use case** terlebih dahulu—auth, domain, alias CRUD, lalu analytics—bukan membangun semua lapisan production di awal. Setelah happy path end-to-end terbukti stabil, lanjutkan ke track **Production-Ready** dengan fokus pada security, reliability, automated QA, dan release polish agar aplikasi benar-benar layak dipakai jangka panjang.
