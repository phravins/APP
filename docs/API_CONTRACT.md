# DueDesk REST integration contract

This is the mobile adapter's explicit proposed contract. Adapt `ApiDueItemRepository` and `ApiAuthRepository` to the deployed Phoenix API; no live backend was supplied or assumed. Base URL includes `/api/v1` when appropriate.

Requests use JSON except multipart document upload. Record payload keys match `toJson()` in `shared/models/models.dart` (camelCase). Envelopes and action parameters below use the specified keys. Dates use ISO 8601 strings; the backend must treat `dueDate` and other date-only fields as civil dates. Timestamps are instants. Enum values match the Dart enum names, for example `inProgress`, `halfYearly`, `member`.

| Method | Path | Payload / response |
| --- | --- | --- |
| POST | `/auth/login` | `{email,password}` → `{user,access_token,refresh_token}` |
| POST | `/auth/register` | `{name,email,password,company_name}` → same auth envelope |
| POST | `/auth/refresh` | `{refresh_token}` → rotated token pair |
| POST | `/auth/forgot-password` | `{email}` → neutral success |
| POST | `/auth/logout` | Revoke current session |
| GET | `/users/me` | `{data: User}` |
| PATCH | `/users/me` | `{name,phone,avatarUrl}` |
| GET | `/workspace` | `{data: WorkspaceData}` scoped to current user |
| GET | `/organisations/:org/due-items` | `page`, `limit`, optional `cursor`; `{data: DueItem[]}` |
| GET | `/due-items/:id` | `{data: DueItem}` |
| POST | `/organisations/:org/due-items` | `{due_item: DueItem}` → `{data: DueItem}` |
| PATCH | `/due-items/:id` | `{due_item: DueItem}` → `{data: DueItem}` |
| POST | `/due-items/:id/start` | Start work; preserve deadline urgency |
| POST | `/due-items/:id/progress` | `{status}` (`upcoming` or `inProgress` only) |
| POST | `/due-items/:id/notes` | `{text}` |
| POST | `/due-items/:id/complete` | `{completion_date,notes,acknowledgement,renew,next_due_date}` → `{next_due_item: DueItem|null}` |
| POST | `/due-items/:id/renew` | `{next_due_date}` → `{data: DueItem}` |
| POST | `/due-items/:id/archive` | Retain record/history/evidence |
| POST | `/due-items/:id/documents` | Multipart `file`, optional `replace_id` → `{data: Document}` |
| GET | `/documents/:id/download` | Authenticated binary response |
| DELETE | `/documents/:id` | Permission check and audit event |
| PATCH | `/organisations/:org` | `{organisation: Organisation}` |
| PUT | `/organisations/:org/categories/:id` | `{category: DueCategory}`; create/update by UUID |
| POST | `/organisations/:org/invitations` | `{name,email,role}` |
| PATCH | `/organisations/:org/members/:id` | `{role,active}`; membership-scoped |
| POST | `/organisations/:org/notifications/read` | `{id}`; `null` means all accessible notifications |

`WorkspaceData` contains arrays `organisations`, `users`, `categories`, `items`, `documents`, `activities`, and `notifications`. `cachedForUserId` is a client-cache field and is not trusted for server access decisions. The aggregate endpoint bootstraps V1; the paginated DueItem contract is available for larger workspaces.

## Enforcement

Authenticate all private endpoints. Scope queries to active memberships; Members can only read and act on assigned items, Admins manage operations, and Owners manage owner roles. Never accept creator IDs, completion state, attachment counts, or role claims from a client without validation. Prevent the last active owner from being removed and keep membership deactivation scoped to its organisation.

Completion and successor creation must be one database transaction with row locking or an equivalent unique predecessor constraint. Retries must not create duplicate successors. Archive replaces hard deletion; completion history and evidence are retained. Store audit events with the authenticated actor and server timestamp.

Validate real file contents, extensions, MIME types, access rights, and limits on the server. Use private object storage; issue authorized downloads instead of public evidence URLs. Demo previews use bundled PDFs or local Hive bytes.

## Errors and token lifecycle

The app maps 401 to authentication failure, 403 to permission failure, 400/422 to validation failure, 404 to missing record, and network/timeouts to offline feedback. Do not send stack traces or credentials in client-facing responses. A 401 triggers one token refresh and one replay per request. Production refresh tokens should rotate and support revocation. The client does not install a request/response logging interceptor.

## Notifications and realtime

Reminders are configuration, not client-authoritative schedules. The server should schedule against the organisation timezone and apply user delivery preferences. Add push registration and delivery behind `NotificationService`; publish due-item identifiers on `dueItemLinks` for navigation. A future Phoenix Channels adapter can invalidate Riverpod data without coupling widgets to socket events. No OAuth, Firebase, push delivery, or SMTP response is fabricated in demo mode.
