# V5 local parameter correction — 2026-10-26

## Evidence and failed precondition

USER-REPORTED NATIVE EVIDENCE: MATLAB R2026a/Simulink26.1 stopped Stage A at phase4_build.m line119, the required-parameter assertion. The owner read the partial block LRC_Phase4_PID_Isolated/CN_Controller/Native_PID: BlockType=SubSystem, MaskType=PID 2dof, ReferenceBlock=slpidlib/PID Controller (2DOF). Its DialogParameters contains LimitIntegrator (Boolean,off,prompt Limit output), UpperIntegratorSaturationLimit (inf), LowerIntegratorSaturationLimit (-inf), and the distinct LimitOutput (Boolean,off,prompt Limit output). It does not expose LimitIntegratorOutput. These observations were supplied in the user's message; no local MATLAB session or failed-output files were accessed by this preparer.

V4 expected LimitIntegratorOutput, so its strict required-field precondition failed before subsequent native configuration. V4's ZIP/hash/components were valid; this is an observed native API compatibility failure, not archive corruption. V4 and all prior releases remain unchanged. Historical expectation names and previous external-documentation references are retained as historical evidence, not used to override the inspected block.

## Exact correction

The executable builder requires LimitIntegrator and explicitly sets it off. LimitOutput remains independently required and explicitly off because the separate actuator Saturation blocks apply the ±5V limits. UpperIntegratorSaturationLimit and LowerIntegratorSaturationLimit are also required. Their initial strings must parse to positive/negative infinity respectively; the builder never replaces them. After the native configuration (including discrete-method settings where applicable), it asserts both enable flags are off and both integrator-limit values are unchanged (numeric comparison tolerates equivalent inf/Inf spelling). Thus the integrator limit group is distinguished by its own enable/upper/lower parameter names from the controller-output limit group despite their similar GUI prompts.

The existing all(isfield(dp,required)) assertion remains intact, with no fallback name or weakened validation. A real missing required field or unexpected default stops construction. The four-controller architecture, gains, plant, source-model identity, anti-windup equations, sampling, solver, test criteria and overshoot calculations are unchanged.

## Static evidence and limitations

Source-derived regression tests extract the actual required list and native set_param arguments, check the independent flags, verify missing-field rejection for every required field, and inspect the bound-preservation assertions. Synthetic metadata fixtures are not MATLAB execution. Existing Stage A/B and early stress-guard tests remain unchanged. No sim/run call is introduced into construction. MATLAB source syntax is independently parsed. Full exact source diff, before/after source hashes, final component verification logs, and preservation checks accompany this release.

The old name can remain in historical records, patches and this explanatory addendum, and as a forbidden-name string in the static test. The executable V5 builder and current configuration statement use only the owner-observed parameter. Native construction/compilation success remains UNVERIFIED until separately authorized owner-side execution. There is no claim of native equivalence, robustness, deployment readiness or project acceptance.

## Preservation and handoff

The failed Stage A output and owner approval record reside on the owner's computer; they were not accessed, renamed, overwritten or repaired here. Keep them unchanged. A future authorized V5 attempt must use a new directory and a separate approval bound to V5, rather than modifying the failed directory or reusing V4 authorization. This preparation authorizes no native execution.

Current audited source hash:3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1.
Original manifested model hash:f1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f.
Their provenance discrepancy remains unresolved. Phase3 Decision2 and all historical analytical failures remain unchanged. Overall NOT ACCEPTED.
