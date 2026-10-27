# Post-Recheck Model Integrity Record

Date: 2026-10-24
Environment: MATLAB R2026a Update 4, Simulink 26.1

## Model identity

File: LRC_Phase2_OpenLoop.slx

Hash recorded in the original native manifest:
f1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f

Current model SHA-256:
3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1

## Recheck findings

Case A fresh-process reproduction: PASS, as reported by MATLAB output.
Case B fresh-process reproduction: PASS, as reported by MATLAB output.

The model hash immediately before and after the Case B recheck was:
3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1

The on-disk model did not change during that check.

An earlier ZIP-format integrity test reported no compressed-data errors.

## Unresolved provenance issue

The current model hash differs from the hash in the original native
manifest. The cause of that difference has not been established.

The original SHA256SUMS_NATIVE.txt has not been changed or replaced.
Its original model-hash discrepancy must remain visible.

Numerical reproduction does not explain the historical hash mismatch.
This record is not a declaration of final Phase 2 acceptance.
