# ADR-0027: Rider sign-up and KYC, checked by hand, with a Verified badge

- **Status:** Accepted
- **Date:** 2026-11-24
- **Context owner:** owner's spec of 2026-11-23, "Become our rider": sign up with full name, WhatsApp phone number,
  email and residential address; then, signed in, a KYC dashboard (permanent address, plate number, Hackney permit,
  NIN, rider's card or licence, a photo of the bike, a printed guarantor form, two guarantors with name, phone, email,
  address, occupation and agreement letter, face verification); submit; Verified badge. Asked, the owner chose to have
  the team check the documents by hand first, not a paid identity service.

## Context

Riders applied with a short form (name, phone, vehicle, plate, licence number) and an admin approved the application,
which made them active straight away. Nothing was checked: no documents, no NIN, no guarantors, no photo of the person.
Storage rules already reserved `applications/{uid}/` for onboarding documents, but no app uploaded any.

## Decision

1. **Sign-up gives the rider app at once.** The rider application (`POST /v1/applications/rider`, the website's
   `/ride` page or "Become our rider" in the rider app) now takes the WhatsApp number, email and residential address.
   It gives the account the `rider` role, a **pending** rider profile and a KYC draft. A pending rider can do their KYC
   but cannot go online ("You can go online once the team has verified your KYC").
2. **The KYC lives in the rider app** (`/v1/rider/kyc`): permanent address and NIN (11 digits), two guarantors' details,
   and seven photos: plate number, Hackney permit, rider's card or licence, the bike, each guarantor's signed form (a
   photo or a scanned PDF) and a selfie for the face check. Answers are saved as the rider goes; **Submit** checks that
   nothing is missing. The guarantor form to print is a page on the website (`/ride/guarantor-form`); its wording is a
   template for a lawyer to review before real riders use it.
3. **The team checks by hand** on the Command Centre's **Rider KYC** page: the full NIN, the guarantors and every
   photo. **Verify rider** makes the rider active and sets `verified_at` (the **Verified** badge in the rider app);
   **Ask for changes** sends a note and marks the items to redo, and the rider fixes them and submits again. Approving
   a rider on the Verification (applications) page does the same and needs a submitted KYC; turning a sign-up down
   suspends the rider. A paid NIN and face-match service can be added later behind the same review step.
4. **Files go through the API**, never straight from the phone to storage: the API checks what each file really is
   (JPEG, PNG or WebP; PDF for the signed forms; by its first bytes, not its name) and that it is at most 5 MB, then
   keeps it privately (`FILE_STORE`: in memory for tests, a git-ignored `.uploads/` folder locally, the Cloud Storage
   bucket under `applications/{uid}/kyc/` online; staging and production refuse to start without `FILE_STORE=gcs` and
   `STORAGE_BUCKET`). Only the rider and the reviewing team can read the files, and they are sent with
   `Cache-Control: private, no-store`.
5. **The NIN is shown in full only to the reviewing team**; the rider sees its last four digits after saving it.

Riders approved before this keep working; their KYC starts as a draft they can complete for the badge.

## Consequences

- Riders now need a phone with a camera and the rider app before they can deliver; the website only signs them up.
- The team must review KYC submissions promptly: riders wait as pending until they do.
- NIN numbers, ID photos and selfies are personal data under the NDPR: keep access to the reviewing team, and decide
  how long to keep the files after a rider leaves (not yet decided).
- The end-to-end check (`e2e_local.py`) and the pilot simulation complete a placeholder KYC before approving a rider.
