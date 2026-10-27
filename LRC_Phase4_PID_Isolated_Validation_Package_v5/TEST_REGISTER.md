# Preregistered tests and proposed numerical criteria — package preparation

All experimental tests below are UNVERIFIED. No MATLAB/Simulink execution occurred. SOURCE refers to baseline/MASTER_EXECUTION_PROMPT.txt. PROPOSED values require owner review before use; no tolerance becomes a contractual requirement by being in a script.

## Requirements-to-test traceability

| Test | Governing reference | Prepared check and scope | Numerical acceptance |
|---|---|---|---|
| Identity | User baseline freeze; master §6, §17 phases 1–2 | Exact source hash, package hashes, copied source, generated model hash and configuration fingerprint | Exact hash match, no substituted source |
| A configuration | §§7D–7E; §11.2; §12 scenarios C/F | Four PID paths, matched gains/DOM/initial conditions, FE/BE Ts=.01, applied saturation with tracking AW | Exact source conventions, zero initial states |
| A stability | §10.4; §13 test 4 | Continuous poles/sample poles, zero-state step evidence, conditional future invariant bound inside rails | Re(poles)<0 or rho<1; tail bound valid; not a global robustness claim |
| A overshoot | §13 test 5 | Peak upper bound, final-value and reference-based overshoot reported for CE/CN/DE/DN separately | Strict <2%; no rounding |
| A settling | §13 test 6 | Entire trajectory with intersample bounds, last-exit bracket, conservative final-entry upper time and conditional future tail | Band [1.4994,1.5606] V; settling upper <.05 s |
| A rise/tracking | §13 tests 7–8; §10.4 | 10–90% rise, final residual, exact equilibrium | No invented rise-time limit; zero analytical equilibrium error; finite-run |error|<=1e-6 V is PROPOSED |
| A control/AW | §7D; §13 test 9 | raw/applied/AW separated, rail and clipping equation, saturation brackets/duration, integrator trajectory | Applied in [-5,5]; correct equations; nominal nonactivation does not prove recovery |
| A equivalence | §7E; §11.2; §13 test 11 | Native-minus-explicit y/raw/applied, I reconstruction/filter monitor, AW, separate continuous/discrete | Master supplies NO applicable numerical tolerance; proposals below |
| B convergence | §11.1; §13 tests 5–6; user's fast-filter requirement | Two solver resolutions, peak/settling changes and original strict limits with convergence allowance | Proposed numerical thresholds below; fail if borderline |
| C supplemental AW activation | §7D conditional recovery; §13 test 9 | Synthetic ref 8 V at0 then1.53 V at.2, stop1, zero load; two precisions | Diagnostic activation, correct FE update/continuous I residual, return to rail-clear tracking; not mandatory master scenario |
| D fresh process | §13 test 12; §17 reproducibility | Load unchanged saved model in new MATLAB process; repeat nominal refined configuration; no builder/save | PROPOSED max difference1e-9 V on y/raw/applied and identical timestamps |
| Future broader work | §7C; §12 scenarios C/D; §17 phase4 | P/PI/PID architecture and load-current disturbance | OUT OF SCOPE, not complete; no acceptance credit |

The master gives no exact saturation-activation waveform. Its load-disturbance scenario is distinct and remains a later obligation; this package does not quietly replace that scenario with a reference pulse. The synthetic 8 V level is deliberately unattainable with the ±5 V actuator, followed by a reachable target to expose recovery. Owner approval is required for this labelled diagnostic. Its temporary failure to track 8 V is not a violation of nominal1.53 V performance.

## Frozen proposed equivalence and numerical tolerances

These are engineering test proposals, not quotations of a master requirement:

- Matched native/explicit maximum absolute y/raw/applied differences <=1e-6 V; I reconstruction and filter-monitor differences <=1e-6 V; AW rate difference <=2e-5 V/s. Report actual discrepancies even if below threshold.
- Nominal final error and diagnostic final recovery error <=1e-6 V at1 s; exact equilibrium tracked separately.
- Saturation algebra residual <=1e-10 V; AW residual <=1e-8 V/s; applied rails remain exact ±5 (no relaxed rail limit).
- Discrete FE integral recurrence <=1e-8 V; BE filter recurrence <=1e-10 V; DOM/reconstructed raw residual <=1e-8 V; held control <=1e-9 V.
- Continuous integrated I trajectory residual <=1e-3 V, accounting for trapezoidal quadrature and the diagnostic reference discontinuity. This coarse auxiliary check does not replace <=1e-6 V native/explicit control equivalence. Reconstructed native I remains labelled.
- Zero initial plant states <=1e-12, controller states <=1e-9; reference/error residual <=1e-10; exact controller sample hits within1e-11 s. Source constants themselves are matched exactly.
- Solver-refinement maximum y difference <=1e-7 V, raw/applied difference <=1e-4 V. Peak upper-bound change <=1e-7 V, settling-upper-bound change <=3e-6 s. Refined peak plus observed peak change must remain strictly below1.5606 V; refined settling upper plus observed change must remain strictly below.05 s. These conservative checks may withhold a verdict even if a point estimate passes.
- Fresh-process comparison <=1e-9 V for y/raw/applied, no interpolation on differing timestamps. Additional signals remain available for audit; a changed grid fails rather than being hidden.

Approve the exact register hash in a separate owner record. Without approval, the execution entry points stop. Changing proposed tolerances later requires a new versioned package/register, not editing this frozen package.

## Solver and metric procedure

Baseline: variable-step ode15s, MaxStep2e-6 s, RelTol1e-9, AbsTol1e-11. Refined: ode15s, MaxStep1e-6 s, RelTol1e-11, AbsTol1e-13. Both stop1 s, all four branches share the solver; all forty signals log at continuous solver output times without decimation or a point limit. Scope appearance does not determine acceptance. R2026a installation and block parameters are checked locally. Dense logs may need several GB of disk/memory for five runs.

These maximum steps are10/20 times smaller than the approximately20 us filter time constant. They capture the early control peak region near9 us and the narrow settling margin; refinement must confirm numerical adequacy. Failure of convergence means stop and audit, not PASS or automatic infinite reruns.

No use of stepinfo defaults. Use the first upward 10%/90% crossings for rise, measured peak time with its logging-resolution limitation, and conservative voltage peak/settling bounds. For a continuous output with |y''|<=M, its linear interpolation error on a segment is <=M*h^2/8. For this stable underdamped plant driven by any bounded |u|<=5 from zero plant states, impulse-response envelopes give |i|<=5*sqrt(1+(sigma/wd)^2)/(L*sigma), |y|<=5/(L*C*wd*sigma), hence M=(5+Rtotal*i_bound+y_bound)/(L*C). This remains valid across held-control changes: y and y' are continuous and y'' is bounded piecewise. Bound every segment, including all intersample segments, rather than five sample endpoints.

The settling upper bound is the end of the final segment whose enclosure intersects outside the band, plus verification of the terminal future bound. Report last outward-crossing bracket separately; it can be empty for a response that enters once. Native noise-free final value is reported, and the nominal exact equilibrium1.53 V gives a separate overshoot calculation. Both overshoot checks must pass. Saturation-duration estimates use left rectangles and event brackets and are labelled as such, not exact event roots.

Finite horizon ends at1 s as specified. The separate modal future bound is analytical evidence conditioned on the configured recurrence and terminal state, NOT an infinite native simulation. Numerical factor10 and1e-9 floor are explicit safety allowances, not formal interval arithmetic. If that bound fails, permanent-settling acceptance is withheld without automatically extending a run.

## Failure logic and outputs

Wrong package/model/configuration/convention, absent/nonfinite/misaligned logs, incomplete time coverage, failed criteria or missing data stop visibly. Results are saved before numerical assertions. All result directories are new and single-use; errors preserve logs and do not authorize rebuilding or rerunning over them. No script assigns overall acceptance or Phase4 completion. Manual Scope review, convergence, fresh-process evidence and owner audit remain separate from individual run checks.
