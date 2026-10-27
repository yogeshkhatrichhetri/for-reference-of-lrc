# Package-preparation review — 2026-10-25

Disposition: READY FOR OWNER REVIEW. Preparation only; no native experiment has been executed.

## Verified baseline

The actual returned-evidence ZIP matches SHA-25629c04f3157984e132ab9b78f930fec851c8d2c31a66307a509e1a90ac89ab434 and its ZIP integrity check passes. Its real native_results/LRC_Phase2_OpenLoop.slx member is76,091 bytes and matches3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1. The package copy is byte-identical. The master matchesc9a36231db3f0e50b1c1d4d29a394f3b431a501c29011d60fc19a246fbebb759. The prior synthesis bundle hash also matches2f7d70d1c35507728cdb2398d0669d3a508466110393cac94e38453d523bb779; no synthesis was repeated.

The old manifested model hashf1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f remains different. Its original manifest and integrity note are copied unchanged. This package does not repair or relabel that discrepancy.

## Prepared scope

Twelve MATLAB source files prepare construction, initialization, integrity/configuration guards, independent continuous and discrete explicit controllers, two native2DOF PID paths, dense native logging, numerical assessment, solver refinement, conditional future-tail checks and fresh-process reproduction. The four physical plants are copied only from the verified source subsystem. No experimental SLX, simulated trajectory, generated-model hash or native PASS result exists yet.

Separate tests cover nominal tracking/equivalence, numerical convergence, and a labelled supplemental saturation/recovery diagnostic. The master has no numerical native-equivalence tolerance or fully specified saturation activation waveform; the proposed register and diagnostic require owner review. Runtime entry points are guarded by a separate owner record whose template is false by default. Current authorization is package preparation only.

R2026a documentation supports the proposed native configuration: parallel2DOF b=1,c=0; FE integral and BE filter for discrete mode; external actuator saturation fed to native tracking with unscaledKt=20 and UseKiTs off. Actual installed mask parameters, compilation, scheduling and trajectories remain unverified. Missing supported configuration or a recurrence mismatch stops the branch instead of altering the equations.

## Static evidence

STATIC_CHECKS.json records14 preparation checks, including independent MISS_HIT0.9.44 parsing of all12 MATLAB source files, Python syntax checks, exact gain literals, source/master identities, correct port paths, component-integrity success, corruption/missing-file rejection, collector overwrite protection and missing-evidence rejection. These are static/tooling checks, not MATLAB checkcode, compilation, or numerical execution.

PRESERVATION_CHECK.json confirms all125 pre-existing workspace files remain byte-for-byte unchanged. No original project file, gain, model, manifest, report, ledger or historical ZIP was rewritten. SHA256SUMS.txt covers every packaged component except itself; the delivery message supplies the outer ZIP hash. The ZIP is independently reopened for integrity/component verification after creation.

## Remaining owner decisions and unverified work

Review the proposed equivalence, residual, convergence and fresh-process tolerances and the8V→1.53V supplemental diagnostic. Separate execution authorization is required before any native step. Native block inspection, construction/compilation, all runs, convergence, genuine Scope observations, saved-model reproduction and later audit remain unexecuted. Neither source inspection nor a future nominal pass establishes robustness, deployment readiness, or full Phase4 completion. P/PI comparison and load-current disturbance remain outside this PID-only subtask.

Historical Phase3 robustness Decision2 remains unchanged. Its engineering concerns are not resolved by this package. The user's scoped departure is explicitly recorded; it is not a retroactive reversal. The original analytical settling failure remains0.07376186885457478s against<0.05s. Overall project NOT ACCEPTED.

Recommended next step: owner review of this frozen package and its proposed test criteria; no MATLAB/Simulink execution in this turn.

READY FOR OWNER REVIEW
