---
name: via-humanos
description: Get human approval before the agent acts. Request someone to approve a payment, sign a document, fill a form, give consent, or verify their identity (KYC). Send secure approval links, track status (pending/approved/rejected), retrieve cryptographic proof of authorization, check mandate validity and constraints, resolve DIDs, and look up users. For compliance-sensitive workflows in finance, legal, healthcare, and HR.
version: 1.0.0
homepage: https://github.com/Humanos-App/via-humanos
user-invocable: true
disable-model-invocation: false
metadata:
  clawdbot:
    requires:
      env:
        - VIA_API_KEY
        - VIA_API_URL
        - VIA_SIGNATURE_SECRET
      bins:
        - curl
        - jq
    os:
      - darwin
      - linux
      - win32
    primaryEnv: VIA_API_KEY
    emoji: "shield"
    homepage: https://github.com/Humanos-App/via-humanos
---

# VIA Humanos — Get Human Approval Before the Agent Acts

Use this skill whenever the agent is about to do something that requires a human to say "yes" first. It sends a secure approval request to the right person — they receive a link, review the details, and approve or reject. The result comes back as a W3C Verifiable Credential with cryptographic proof that the action was authorized.

**The agent should NEVER proceed with a sensitive action (payment, signing, data access, transfer) without first using this skill to get authorization.**

## When to use this skill

Use this skill when the user says things like:

- "I need approval from [someone] before doing [something]"
- "Get authorization from my manager for this payment"
- "Send this contract/document to [someone] for signing"
- "Check if [someone] approved the request"
- "Has the mandate been approved or rejected?"
- "Verify this person's identity before proceeding"
- "Get consent from the user for data processing"
- "Cancel the pending approval request"
- "Look up user [email/phone/DID]"
- "Is this mandate still valid?"

Also use this skill when the agent is about to:

- **Make a payment or transfer** — get approval first
- **Sign or send a contract** — collect digital signature
- **Access sensitive data** — verify authorization exists
- **Execute a high-value action** — check mandate constraints (amount limits, time bounds)
- **Start an onboarding flow** — combine contract + form + consent in one request

Trigger keywords: approval, authorize, mandate, sign, consent, credential, KYC, identity verification, human approval, compliance, permission, delegation.

## Prerequisites

1. A VIA Protocol account with an API key from [humanos.com](https://humanos.com)
2. Environment variables set:
   - `VIA_API_KEY` — Bearer token for API authentication
   - `VIA_API_URL` — Base URL of the VIA API (e.g., `https://api.humanos.com`)
   - `VIA_SIGNATURE_SECRET` — HMAC secret for request signing

## Authentication

All API requests require:

```
Authorization: Bearer $VIA_API_KEY
X-Timestamp: <unix-timestamp-ms>
X-Signature: <hmac-sha256 of body + timestamp using VIA_SIGNATURE_SECRET>
```

Use the signing script: `scripts/sign-request.sh`

## Core Operations

### 1. Create a Credential Request (Get Human Approval)

When the agent needs human authorization for an action:

```bash
scripts/create-request.sh \
  --contact "user@example.com" \
  --type "document" \
  --name "Hotel Booking Authorization" \
  --security "CONTACT" \
  --data '{"label":"amount","value":"€450","type":"string"}'
```

**Parameters:**
- `--contact` — Email or phone number of the person who must approve (required)
- `--type` — Type of credential: `document`, `form`, `json`, or `consent` (required)
- `--name` — Human-readable name for the approval (required)
- `--security` — Security level: `CONTACT`, `ORGANIZATION_KYC`, `HUMANOS_KYC` (default: CONTACT)
- `--data` — JSON data to include in the credential (optional)
- `--language` — Language for the approval UI: `ENG` or `PRT` (default: ENG)
- `--redirect` — URL to redirect user after approval (optional)
- `--internal-id` — Your internal reference ID (optional)

**What happens:**
1. The API creates the request and sends an OTP code to the contact
2. The person opens the link, enters the code, and sees the approval
3. They approve or reject with optional digital signature
4. You receive a webhook or poll for the result

**Response includes:** `requestId` — save this to check status later.

### 2. Check Request Status

```bash
scripts/get-request.sh --id "request-id-here"
```

Returns the full request with all credentials and their statuses (`PENDING`, `APPROVED`, `REJECTED`).

### 3. Find Requests by User

```bash
scripts/find-requests.sh --contact "user@example.com"
# or
scripts/find-requests.sh --did "did:key:z6Mk..."
# or
scripts/find-requests.sh --internal-id "order-123"
```

### 4. Get a Credential with Proofs

```bash
scripts/get-credential.sh --id "credential-id-here"
```

Returns the W3C Verifiable Credential with cryptographic proofs that the human authorized the action.

### 5. Get a Mandate

```bash
scripts/get-mandate.sh --id "mdt_uuid-here"
```

Returns mandate details including scope, validity period, and constraints.

### 6. Get Mandate as Verifiable Credential

```bash
scripts/get-mandate-vc.sh --id "mdt_uuid-here"
```

Returns the mandate in W3C Verifiable Credential format for use in Verifiable Presentations.

### 7. Resolve a DID

```bash
scripts/resolve-did.sh --did "did:key:z6Mk..."
```

Returns the DID Document with verification methods. Use this to verify signatures on credentials.

### 8. Look Up a User

```bash
scripts/get-user.sh --contact "user@example.com"
```

Returns user details, identity information, and associated DIDs.

### 9. Cancel a Request

```bash
scripts/cancel-request.sh --id "request-id-here"
```

Cancels a pending request. This is irreversible.

### 10. Resend OTP

```bash
scripts/resend-otp.sh --id "request-id-here" --contact "user@example.com"
```

Resends the verification code to the user if they didn't receive it.

## Decision Flow

When you need human approval, follow this flow:

1. **Create request** → `scripts/create-request.sh`
2. **Wait for approval** → Poll with `scripts/get-request.sh` or wait for webhook
3. **Check result:**
   - `APPROVED` → Proceed with the action. The credential contains cryptographic proof.
   - `REJECTED` → Do NOT proceed. Inform the user the action was denied.
   - `PENDING` → Still waiting. Ask the user if they want to resend the OTP.

## Security Levels

| Level | Description | Use When |
| --- | --- | --- |
| `CONTACT` | OTP verification only | Low-risk actions (view data, basic approvals) |
| `ORGANIZATION_KYC` | Organization-level identity check | Medium-risk (sign documents, access records) |
| `HUMANOS_KYC` | Full KYC with identity verification | High-risk (payments, legal signatures) |
| `HUMANOS_REVALIDATION` | Re-verification of previously verified identity | Periodic re-checks |

## Credential Types

| Type | Description | User Experience |
| --- | --- | --- |
| `document` | PDF document for review and signature | User sees PDF, can draw signature |
| `form` | Dynamic form with fields | User fills form fields step by step |
| `json` | Structured data for review | User sees data and approves/rejects |
| `consent` | Consent text or URL | User reads and agrees to terms |

## Rate Limits

- Request creation: 60 requests per 60 seconds
- Max 10 credentials per request
- Max 100 contacts per request

## Error Handling

- **401 Unauthorized** — Check VIA_API_KEY and signature
- **404 Not Found** — Request or credential doesn't exist
- **429 Too Many Requests** — Rate limit hit, wait and retry
- **400 Bad Request** — Check request body format

## Output Format

Always present results to the user in this format:

**For request creation:**
> Request created successfully. An approval link has been sent to [contact].
> Request ID: [id]
> Status: PENDING

**For status checks:**
> Request [id] — Status: [APPROVED/REJECTED/PENDING]
> Credential: [name] — [status]
> Approved by: [contact] on [date]

**For errors:**
> Failed to [action]: [error message]
> Suggestion: [what to do next]

## External Endpoints

| Endpoint | Data Sent | Purpose |
| --- | --- | --- |
| `$VIA_API_URL/v1/request` | Contacts, credential data | Create approval requests |
| `$VIA_API_URL/v1/request/:id` | Request ID | Check approval status |
| `$VIA_API_URL/v1/credential/:id` | Credential ID | Retrieve signed credentials |
| `$VIA_API_URL/v1/via/mandates/:id` | Mandate ID | Get mandate details |
| `$VIA_API_URL/v1/via/dids/:did` | DID identifier | Resolve DID documents |
| `$VIA_API_URL/v1/user` | Contact/DID/internal ID | Look up users |

## Security and Privacy

- API keys are read from environment variables, never hardcoded
- All requests are signed with HMAC-SHA256
- Credentials contain W3C Verifiable Credential proofs (EdDSA)
- User contact information (email/phone) is sent to the VIA API for OTP delivery
- No data is stored locally by this skill
