# SomaSafe Monorepo (Undergraduate Thesis Project)

SomaSafe is a federated learning system for cardiovascular anomaly detection on PPG
(photoplethysmography) signals. The privacy premise drives the whole design: raw sensor
data never leaves the user's devices. An ESP32 wearable acquires the signals and runs a
small anomaly model on them; an Android phone hosts on-device training; the server only
ever sees model weight updates, which it aggregates into new global model versions and
redistributes.

## Repository structure

Each module is a Git submodule (`git submodule update --init` after cloning) with its own
README covering internals, current status and roadmap.

| Module | Role in the system | Current state |
| --- | --- | --- |
| `backend/` | Model definitions + training on PPG-DaLiA, dataset pipeline, trainable/int8 `.tflite` exports; aggregation + distribution server | FeatureMLP anomaly classifier trained and exported end to end; four-stage dataset pipeline; FastAPI gateway + Celery worker (Redis broker, Postgres store) serve versioned models (hand-bumped versions with a fingerprint tripwire; frozen history, only the latest trains), quantize + sign uploaded weights asynchronously or accept submit-only updates, and aggregate submitted weight updates into new global weights daily (FedAvg with validation + z-score outlier filtering, hand-revocable rounds), re-baking signed serving artifacts each round |
| `application/` | Android app: BLE relay to the ESP32 + on-device LiteRT training + federated client | Compose shell, BLE scan + GATT browser, firmware BLE contract (PPG/ML parsing, model upload, attestation), capture storage + preprocessing (including the wearer's own z-score parameters, per capture group), versioned model downloads (weights baked into the trainable artifact, `min_app_version` gate), on-device training (local epoch over a capture, windows normalized on the phone), both dense federated upload paths (upload-&-quantize and submit-only; `secure` models are gated out), and app-side assembly of the signed device payload with the client's norm block. Upload retry strategy and a secure-aggregation client still pending |
| `firmware/` | ESP32-S3 NimBLE peripheral: streams PPG/ACC, receives `.tflite` models over BLE, runs int8 inference with TFLite Micro | PPG streaming, model-transfer and ML-results BLE services working; on-device 17-feature extraction + FeatureMLP inference; UART test harness simulates the sensor |

## Architecture and shared concerns

See [`shared/docs/architecture.md`](shared/docs/architecture.md) for the three-tier
design (ESP32 / Android / server), the training and distribution data flow, and how the
per-hop security model fits together. Topics shared by more than one module — device
attestation, authentication, BLE protocol, model types, model signing, submission types,
versioning semantics, secure aggregation, anomaly labelling and distillation — each have
their own doc under [`shared/docs/`](shared/docs/); the module READMEs link to them instead
of repeating them.

## Shared directory

`shared/` holds cross-module content (protocol files, common scripts, and a `gen/`
subdirectory for build output one project produces and another consumes, like the
backend's exported dataset/models or the firmware's factory keys). See
[`shared/README.md`](shared/README.md) for what's in it and how `make shared` links or
clones it into each module.

