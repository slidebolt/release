# Speech providers

`sb-speech` owns calls, RTP audio, segmentation and speech events. Recognition
and synthesis are optional HTTP providers. A provider is not a plugin, device or
entity, and consuming plugins never know which engine implements it.

## Local Docker engines

The standard overlay runs isolated Whisper and Piper containers and supplies
their internal URLs to SlideBolt:

```sh
docker compose -f compose.yml -f compose.speech.yml up -d
```

The provider ports bind to host loopback only. The engines and models are not
present in the main SlideBolt image. Remove the overlay to return to the
dependency-free transport service.

## Another provider

Set one or both endpoints in `.env`:

```dotenv
SPEECH_TRANSCRIBER_URL=http://127.0.0.1:9001
SPEECH_TRANSCRIBER_TOKEN=
SPEECH_SYNTHESIZER_URL=http://127.0.0.1:9002
SPEECH_SYNTHESIZER_TOKEN=
```

The service must implement `sb-speech-provider-sdk` contract version 1. Missing
endpoints are valid: SlideBolt starts and reports that capability unavailable.
Quickstart accepts the same URLs and does not install Docker, binaries or models.

## Provider contract

Providers expose capabilities and health, accept mono WAV for transcription,
and return mono PCM WAV for synthesis. Use the SDK's shared handler and
conformance tests rather than adding engine-specific behavior to `sb-speech`.
