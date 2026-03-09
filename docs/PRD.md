
# Cloudflare Email Manager Mobile
Product Requirements Document (PRD)

Version: 1.0
Date: 2026

---

## 1. Overview

Cloudflare Email Routing memungkinkan pengguna membuat banyak alamat email alias tanpa harus mengelola mailbox sendiri. Email yang dikirim ke alias tersebut akan diteruskan ke inbox tujuan.

Aplikasi ini menyediakan **mobile interface** untuk:

- Create email alias
- Edit alias
- Delete alias
- Generate privacy email
- Monitor catch‑all usage
- View email routing activity

---

## 2. Goals

Primary goals:

- Mempermudah pengelolaan email alias
- Memberikan mobile-first experience
- Privacy email generator
- Monitoring email routing

---

## 3. Non Goals

Aplikasi ini **tidak menyediakan**:

- SMTP server
- Email sending
- Email inbox client

---

## 4. Architecture

Mobile App akan langsung memanggil Cloudflare API.

Mobile App  
↓  
Cloudflare REST API  
↓  
Cloudflare GraphQL API

---

## 5. Authentication

User login menggunakan **Cloudflare API Token**.

Header request:

Authorization: Bearer API_TOKEN

Required permissions:

- Zone:Read
- Email Routing Rules:Read
- Email Routing Rules:Edit
- Email Routing Addresses:Read
- Email Routing Addresses:Edit

---

## 6. Domain Discovery

Domain diambil otomatis dari Cloudflare.

Endpoint:

GET /client/v4/zones

User kemudian memilih domain yang ingin dikelola.

---

## 7. Email Alias Management

Alias email dibuat menggunakan **routing rules**.

Endpoints:

List rules  
GET /zones/{zone_id}/email/routing/rules

Create rule  
POST /zones/{zone_id}/email/routing/rules

Update rule  
PUT /zones/{zone_id}/email/routing/rules/{rule_id}

Delete rule  
DELETE /zones/{zone_id}/email/routing/rules/{rule_id}

---

## 8. Destination Email

Destination email harus diverifikasi sebelum digunakan.

Endpoint:

POST /accounts/{account_id}/email/routing/addresses

---

## 9. Core Features

### Alias CRUD

User dapat:

- Create alias
- Edit alias
- Delete alias
- Enable / Disable alias

---

### Alias Generator

User dapat generate email alias otomatis.

Format:

service-random@domain.com

Example:

amazon-k39sj@example.com

---

### Disposable Alias

Alias dapat dibuat dengan TTL.

Options:

- 1 hour
- 1 day
- 7 days

---

### Catch‑All Monitor

Catch‑all menangkap email yang tidak memiliki alias rule.

App akan mendeteksi alamat baru dari activity logs.

User dapat:

- Create alias
- Ignore
- Block

---

### Email Activity Logs

Menggunakan GraphQL analytics API untuk melihat aktivitas email.

Data yang ditampilkan:

- Email address
- Status (forwarded / dropped / rejected)
- SPF
- DKIM
- DMARC

---

## 10. Data Model

### Domain

id  
zone_id  
name  

### Alias

rule_id  
zone_id  
alias  
destination  
enabled  

### ActivityLog

timestamp  
email_to  
action  
spf  
dkim  
dmarc  

---

## 11. Navigation Structure

Bottom Navigation:

- Dashboard
- Aliases
- Catch-All
- Activity
- Settings

---

## 12. MVP Scope

MVP features:

- Login with API token
- Domain selector
- Alias CRUD
- Alias generator
- Catch‑all monitor
- Activity logs

---

## 13. Future Features

Potential improvements:

- Bulk alias import
- Alias analytics
- Spam detection
- Worker integration
- Multi destination forwarding

---

## 14. Success Metrics

Metrics:

- Alias created
- Active domains
- Daily users
- Emails routed
