# Android client quickstart

SlideBolt clients are data-driven: discover an installation, pair once, list
devices and entities, then render the commands advertised by each entity. Do
not add plugin-specific logic to the app.

## Discover and pair

1. Use Android NSD to browse `_slidebolt._tcp.local`.
2. Read the `api` TXT value and request `<api>/.well-known/slidebolt`.
3. `POST <api>/pairing/requests` with a client name and type.
4. Display the returned `code`; an administrator enters it on the Clients page.
5. Poll `POST <api>/pairing/requests/{id}/exchange` with the returned verifier.
6. Store the one-time bearer token in Android Keystore-backed encrypted storage.

```json
{"clientName":"Living Room TV","clientType":"android-tv","requestedAccess":"control","requestedSecurityGroups":["*"]}
```

## Use the API

Download the machine-readable contract from `<api>/openapi.json`. Every normal
request uses `Authorization: Bearer <token>`.

- `GET /devices` and `GET /entities` provide the initial snapshot.
- `GET /definitions` describes device classes, entity types, and commands.
- `GET /ws/events?pattern=>` streams `snapshot`, `upsert`, and `remove` events.
- `POST /entities/{plugin}/{device}/{entity}/command/{action}` executes an
  action listed by that entity; the request body is the command payload.

Treat entity state and plugin-defined payload extensions as JSON objects. A
client should never infer behavior from a plugin name.

## Authentication behavior

Only OpenAPI/schema documentation, installation metadata, pairing creation,
and pairing exchange are public. Devices, entities, events, commands, tokens,
scripts, schedules, and pairing approval require bearer authentication.
