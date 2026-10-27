# Frozen identity and scoped authorization — 2026-10-25

Package-preparation scope only. Overall project NOT ACCEPTED. The user explicitly authorized a separate research-only nominal PID implementation-validation package as a scoped departure from the robustness-readiness recommendation. This does not overturn Decision 2, authorize execution now, or qualify deployment/robustness. The original report is copied unchanged into baseline/.

## Source chain

Original local returned archive: upload/LRC_Phase2_Returned_Evidence.zip

Archive SHA-256: 29c04f3157984e132ab9b78f930fec851c8d2c31a66307a509e1a90ac89ab434

Exact member: native_results/LRC_Phase2_OpenLoop.slx (76,091 bytes).

Actual extracted and package-copy SHA-256:
3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1

Original native-manifest entry:
f1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f

The discrepancy is UNRESOLVED. The copied native manifest remains unchanged, refers to its original directory layout, and is not the package manifest. Verifying it against the current source is expected to expose the historical model mismatch. Do not regenerate it. No continuity with the originally manifested model is claimed.

Master: baseline/MASTER_EXECUTION_PROMPT.txt
SHA-256 c9a36231db3f0e50b1c1d4d29a394f3b431a501c29011d60fc19a246fbebb759.
Recovered from phase3_sources/LRC_Control_Construction_CANDIDATE.zip. Its init_lrc_pid.m is included strictly as historical source, outside the MATLAB path. Never execute it.

## Experiment relationship

There is NO newly generated experimental SLX in this package. baseline/LRC_Phase2_OpenLoop.slx is the genuine, unchanged audited source, not a fabricated experiment. Later, the builder loads this copy, copies only Physical_LRC into four independent new branches with add_block, creates independent controller paths, and saves a new model in a P4_RUN_* sibling. It never saves the source. The source has zero i/y states, series R+Req=50 ohm, L=1 H, C=510e-6 F; every load port is connected to zero. No original controller builder is executed.

Generated model hash: UNVERIFIED / NOT YET GENERATED. The local build_record.json will record it immediately after saving. Before each run and after each completed run the same saved bytes must match. SimulationInput overrides do not save the model. The fresh-process check loads that exact model, never rebuilds it.

PROTECTED_INPUTS.json records SHA-256 of all 125 pre-existing workspace files present when this package began. PRESERVATION_CHECK.json records the later byte comparison. This is an evidence snapshot, not a replacement historical ledger. baseline/ copies and all source artifacts retain their original bytes.

Historical results preserved: analytical PID settling 0.07376186885457478 s FAIL against <0.05 s, approximately 1.6175747991% overshoot PASS; rejected fast candidate sampled radius approximately 1.02376446. Phase 2 closure applies to the current hash with its disclosed limitations. Nothing in this package reclassifies those records.
