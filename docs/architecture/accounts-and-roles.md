---
summary: Signup by emailed code, password login, the member → editor → administrator ladder, per-profession grants, suspension, public profiles.
paths:
  - "app/models/user.rb"
  - "app/models/user/**"
  - "app/models/signup.rb"
  - "app/models/session.rb"
  - "app/models/current.rb"
  - "app/models/editorship.rb"
  - "app/models/email_change.rb"
  - "app/models/concerns/session_verification_code.rb"
  - "app/controllers/concerns/authentication.rb"
  - "app/controllers/concerns/signup_flow.rb"
  - "app/controllers/sessions_controller.rb"
  - "app/controllers/signups_controller.rb"
  - "app/controllers/signups/**"
  - "app/controllers/passwords_controller.rb"
  - "app/controllers/account_settings/**"
  - "app/controllers/profiles_controller.rb"
  - "app/controllers/admin/users_controller.rb"
  - "app/controllers/admin/suspensions_controller.rb"
---

# Accounts and roles

Hand-rolled auth à la Writebook: `has_secure_password`, `Session` with a signed
permanent cookie, `Current` + the `Authentication` concern. No Devise, no second login
mechanism, no HTTP Basic.

```mermaid
flowchart LR
  member -- "granted a profession<br>(Editorship)" --> editor["editor «Эксперт»<br>can_edit_content?"]
  editor -- "promoted" --> administrator["administrator<br>can_administer?"]
```

- **Signup** (Fizzy pattern): email → 6-char code (15 min) → name + password. `Signup`
  is a PORO; the `User` is created only at the final step. **Production signup
  requires SMTP.** Login stays password-based on purpose; a founder welcome `<dialog>`
  follows signup.
- **Password reset**: `generates_token_for` + `PasswordsController` + mailer.
- **Trust ladder**: `Editorship` scopes editor rights to granted professions; admins edit
  everything and need no grant; only admins publish; an admin can't change their own role.
  First admin comes from `ADMIN_EMAIL`/`ADMIN_PASSWORD` in the seed.
- **A grant is a public role**: every active grant holder is named on the map («Карту
  ведёт», lesson byline, JSON-LD `reviewedBy`); the «Проверено» mark carries the
  verifier's name and date. A map is never anonymous.
- **Suspension**: `users.suspended_at`; `suspend!` revokes sessions and
  `User.active.authenticate_by` blocks login; `reinstate!` reverses; self-suspend guard.
  No durations, IP or partial blocks.
- **Public profiles** (`/u/:handle`): a visiting card, not a social layer — name,
  self-labelled headline, role mark, joined month, the personal map, curated professions,
  accepted edits; learning progress only when `users.show_progress`. The handle is
  generated on first map creation and editable in account settings. No karma, badges or
  followers.
- **Photos**: generated-initials avatars for everyone; grant holders may upload a photo
  (`User::Photo`: one 256px WebP, EXIF stripped, original discarded). Members have none
  ([decision](../decisions/2026-06-24-no-uploads-on-private-models.md)).
