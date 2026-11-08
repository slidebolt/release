# Asterisk for SlideBolt

SlideBolt does not run Asterisk. It connects to yours through ARI (the Asterisk
REST Interface), using asterisk-host. These are the pieces of Asterisk
configuration SlideBolt relies on; merge them into your own files. They match the
example service in `.env.example`:

    ASTERISK_HOST_SERVICES={"4000":{"name":"Agent","call":"agent","text":true}}

| File | What it adds |
|---|---|
| `ari.conf`, `http.conf` | ARI on 127.0.0.1:8088 with a `slidebolt` user. Put its password in `ASTERISK_ARI_PASS`. |
| `extensions.conf` | Calls to 4000 go to SlideBolt (`Stasis(slidebolt,service,4000)`). Texts between phones keep working, and texts to 4000 are left for SlideBolt. |
| `pjsip-endpoint.conf` | The two settings each phone endpoint needs: its call `context` and `message_context`. |

Rules that matter (each one was found the hard way):

- Every rule in the message context is a single priority and never calls
  `Hangup()`. A second priority on the catch-all would also run for 4000, and
  `Hangup()` leaves Asterisk's message channel stuck.
- A service number needs its own do-nothing rule in the message context, or the
  catch-all tries to deliver the text to a phone that does not exist.
- `;` starts a comment anywhere in a dialplan line, including inside `NoOp()`.

The Lua scripts in `../scripts/agent-line` and `../scripts/agent-text` connect
service 4000 to the OpenCode agent. Save them as automations (UI, sb-api or the
MCP `save_script` tool). They assume the call name `agent` and the number 4000;
change both together if you use others.
