# PHASE 3 — CONSTRAINED ANALYTICAL SAMPLED-PID SYNTHESIS REVIEW

Date: 2026-10-24. Supplemental record. Historical files and dispositions remain unchanged.

## Executive decision

**A nominal analytically feasible four-parameter controller was found and independently assessed. It meets the strict sampled criteria and the continuous-controller comparison criteria. It is numerically distinguishable from a boundary pass, but its continuous performance is fragile. No robust engineering acceptance or native implementation approval is issued by this report. Overall project remains NOT ACCEPTED.**

The earlier bounded searches did not identify a combined solution. An explicitly preregistered extension of the filter bound identified the finalist. Thus those unsuccessful searches must not be described as an infeasibility proof. Nor does this one nominal feasible point certify disturbance recovery, noise tolerance, model uncertainty, hardware timing or native block equivalence.

Selected analytical finalist (full precision; not written into project scripts):

| Parameter | Value | Units |
|---|---:|---|
| Kp | 2.050062959107108 | V/V |
| Ki | 40.633656994693226 | s⁻¹ |
| Kd | 0.027442375755061164 | s |
| N | 49999.552453856028 | s⁻¹ |
| Ts | .01 | s |
| Kaw | 20 | s⁻¹ |

The filter is unusually fast: 1/N≈2.0000179e-05 s, N/(2π)≈7957.675925 Hz, versus100 Hz controller updates. This is an analytically useful limiting design, not a bandwidth recommendation for noisy hardware.

## Continuity and evidence classification

**SOURCE:** master sources/MASTER_EXECUTION_PROMPT.txt, SHA-256 `c9a36231db3f0e50b1c1d4d29a394f3b431a501c29011d60fc19a246fbebb759`; source parameters and explicit controller recurrence from init_lrc_pid.m; the prior Phase 3 review and Phase 2 closure/addenda. The master's continuous/discrete comparison remains applicable. Requirements were not waived when sampled-only candidates succeeded.

**Current audited open-loop model:** `3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1`.

**Original native-manifest entry:** `f1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f`.

Their historical discrepancy remains unresolved. No continuity with the originally manifested model is claimed. No original manifest was regenerated.

**HISTORICAL ANALYTICAL:** Kp1.2209160924482672, Ki33.16839344262296, Kd.024783622571933332,N244; continuous OS1.6175747991% PASS, settling **.07376186885457478 s FAIL** against<.05 s. Later sampled predictions≈4.67597%/.17337 s remain recorded. Rejected fast sampled radius≈1.02376446 remains an unstable rejection. None is relabelled by this new design.

**NATIVE:** Phase 2 only: previously audited Case A29/29, Case B30/30, six reproduction comparisons per case and reviewed screenshots. Phase 2 remains CLOSED with its cursor-availability and provenance limitations. No new native evidence was generated.

**DERIVED:** all new values in this report are analytical numerical evaluations using exact held-input plant propagation, polynomial roots, rational functions and independent nonlinear ODE integration. They are not MATLAB/Simulink results. **DESIGN CHOICE:** bounds, seeds, objective, optional margins, ideal noiseless measurement, nominal parameters, zero initial conditions, zero load, aligned step and zero computational delay.

## Mathematical formulation

With x=[i,y], L=1 H,C=.000510 F,Rtotal=50 ohm,

`i'=u−50i−y`, `y'=i/C`; hence `P(s)=.000510 s²+.0255 s+1` and G=1/P.

Input and output are volts. At equilibrium i=0,y=u=r=1.53 V. This is a voltage-driven plant, not a current-driven substitute.

Unity negative feedback and parallel filtered PID give

`s(s+N)P(s)+Kp s(s+N)+Ki(s+N)+Kd N s²=0`.

Independent expansion:

| Contributor | Polynomial contribution |
|---|---|
| s(s+N)P | a s⁴+(b+aN)s³+(1+bN)s²+N s |
| Kp term | Kp s²+KpN s |
| Ki term | Ki s+KiN |
| Kd term | KdN s² |

`Q=[a, b+aN, 1+bN+Kp+KdN, N(1+Kp)+Ki, KiN]`, a=.000510,b=.0255. Coefficient units are respectively s²,s,1,s⁻¹,s⁻², so every polynomial term has units s⁻². All finalist coefficients are positive, but stability is established by computed roots, not their signs alone.

Finalist coefficients: `[0.00051, 25.525271751466576, 2650.1451565560437, 152542.41656843387, 2031664.664298158]`.

DOM reference transfer is `(Kp s+Ki)(s+N)/Q(s)`, with zeros `[-19.820687366787485, -49999.55245385603]`. It is not the derivative-on-error transfer, whose numerator includes KdN s². The search used the full reference response rather than ideal cubic pole assignment. Step residues and poles are recorded in FINAL_ASSESSMENT.json. Numerator/denominator interaction explains why moving poles alone did not ensure performance.

Continuous roots (real, imaginary): `[[-49945.63193306512, 0.0], [-42.98624541124959, 50.95209729213438], [-42.98624541124959, -50.95209729213438], [-17.948029968424144, 0.0]]` s⁻¹. The complex pair has damping ratio≈0.644831; this does not license a second-order approximation of the full response. The slow pole and nearby zero affect the tail, and the fast filter pole is not ignored.

For sampled operation, α=1/(1+N Ts),β=KdNα:

`raw_k=Kp(r−y_k)+I_k−β(y_k−fprev_k)`;
`u_k=clip(raw_k,−5,5)`;
`I_(k+1)=I_k+Ts[Ki(r−y_k)+20(u_k−raw_k)]`;
`fprev_(k+1)=α fprev_k+(1−α)y_k`.

The plant evolves exactly as `x_(k+1)=Ad x_k+Bd u_k`, Ad=exp(A Ts), Bd=∫exp(Aτ)B dτ. Current/output between samples use the exact constant-input solution. No Euler approximation is applied to the plant. Raw/applied control and AW correction are distinct quantities.

With X=[i,y,I,fprev], U=[0,−Kp−β,1,β], linear unsaturated F has top rows `[Ad,0,0]+Bd U`, row3 `[0,−Ts Ki,1,0]`, row4 `[0,1−α,0,α]`. Sampled poles: `[[0.3355548688121209, 0.5392788751440578], [0.3355548688121209, -0.5392788751440578], [0.787662889162849, 0.0], [0.6040956690409279, 0.0]]`. Radius=0.787662889162849. These are not exp(continuous roots·Ts).

## Preregistered search and amendments

Read PREREGISTRATION.md and the three named amendment files in chronological order: JOINT_SEARCH_AMENDMENT.md, BOUNDARY_SEARCH_AMENDMENT.md, HIGH_FILTER_AMENDMENT.md. Each was written before its associated evaluations. Later discoveries are not presented as original preregistration.

All four coordinates are log10 gains. Primary domain: Kp[.01,12],Ki[.1,1200],Kd[1e-5,.3],N[10,1000]. Expanded domain: Kp[.001,40],Ki[.01,5000],Kd[1e-6,1],N[1,5000]. These include historical sets and permit saturation; positive-gain boundaries exclude zero/negative gains and infinite limits. Neither box is a global feasibility domain.

Differential evolution used population80 (multiplier20 for four variables), deterministic seeds17,43,101,250 generations, tol1e-8,atol1e-10, vectorized deferred updates; bounded Powell refinement followed. First the sampled-only score was optimized; then a joint continuous/sampled score. Original score was max(normalized overshoot, normalized maximum band error after.049 s, rho/.98), plus instability penalties. The .049 s deadline and .98 radius were optional design margins, not mandatory criteria. The sampled objective checks all interval extrema through1 s using current zero crossings. Continuous joint screening used saturated RK4 h=.00025 s through.5 s and was not used for final acceptance.

Boundary runs removed optional margins (deadline.05, normalization1) with two400-generation seeds in the expanded box; best score remained1.00033656 at N≈5000. A separate sampled N≤314 diagnostic passed sampled criteria, demonstrating that the sampled result does not require the very high filter bandwidth. It did not establish a combined solution.

Because the joint boundary was near feasibility and N was at its limit, a focused high-filter search was preregistered: Kp[1.7,2.4],Ki[30,55],Kd[.02,.04],N[1000,50000], seeds17,43,300 generations. This branch used continuous modal exponentials rather than an unstable/stiff coarse RK4 approximation. It explicitly constrained linear raw effort below rails; final saturation-aware ODE checks and raw extrema validate that restriction for the finalist. Clipping candidates would not qualify through this unsaturated branch. The sampled side continued to apply the actual saturation/AW law.

Mandatory tests are strict OS<2%, permanent settling<.05 s, correct equilibrium tracking, rho<1 and applied rails inclusive. The extra continuous comparison was retained. Numerical acceptance headroom was preregistered at1e-6 V and1e-6 s; it is separate from an engineering robustness margin. The finalist exceeds that numerical headroom but has little engineering slack.

### Search outcomes and convergence

DE vectorized evaluation counts below count batches, usually80 candidate evaluations per batch; local counts are scalar calls. A maximum-generation termination is reported honestly and is not an optimality certificate. Powell success is a local termination condition, not proof of global optimality.

| Search | Domain / seed | DE score | Final local score | DE termination |
|---|---|---:|---:|---|
| sampled | primary / 17 | 0.7100744746 | 0.7100744483 | generation limit |
| sampled | primary / 43 | 0.7100744649 | 0.7100744297 | generation limit |
| sampled | primary / 101 | 0.7100744671 | 0.7100744366 | generation limit |
| sampled | expanded / 17 | 0.704685756 | 0.7046857135 | generation limit |
| sampled | expanded / 43 | 0.7046860314 | 0.7046857831 | generation limit |
| sampled | expanded / 101 | 0.7046856589 | 0.7046856548 | generation limit |
| joint | primary / 17 | 1.188362023 | 1.188362018 | converged |
| joint | primary / 43 | 1.188362026 | 1.188362016 | converged |
| joint | primary / 101 | 1.188362024 | 1.188362019 | converged |
| joint | expanded / 17 | 1.066355697 | 1.06635569 | generation limit |
| joint | expanded / 43 | 1.066355676 | 1.066355676 | generation limit |
| joint | expanded / 101 | 1.066355674 | 1.066355673 | generation limit |
| boundary | joint_optional_margins_removed / 17 | 1.000336566 | 1.000336564 | converged |
| boundary | joint_optional_margins_removed / 43 | 1.000336565 | 1.000336564 | converged |
| boundary | sampled_N_le_314 / 17 | 0.7494282732 | 0.7494282732 | generation limit |
| high filter | focused / 17 | 0.9974474682 | 0.9974474664 | converged |
| high filter | focused / 43 | 0.9974474742 | 0.9974474737 | generation limit |

The selected high-filter seed17 score is0.99744746636. Two independent seeds converged to essentially the same nominal region, but both remain near the chosen N upper bound. This suggests a limiting trend, not uniqueness or global optimality. A temporary batched-array shape error in the new high-filter search code was fixed before successful optimization; it produced no candidate evidence. The reproducible final source is supplied.

## Independently recomputed hard-constraint table

The step begins at t=0; all times are elapsed seconds from that event. Rise is first crossing of.153 V to first crossing of1.377 V. Settling is the final inward crossing of the closed band[1.4994,1.5606], with later excursions excluded by localized extrema and future-tail bounds. The initially outside interval is not called an outward band crossing.

| Test | Sampled controller / continuous plant | Continuous controller | Disposition |
|---|---:|---:|---|
| Peak voltage,V | 1.54787540669262 | 1.56052987843638 | Below1.5606 |
| Peak time,s | 0.103086582062732 | 0.0652807829507081 | Reported, no invented target |
| Overshoot,% | 1.16832723481153 | 1.99541689126667 | Both strictly<2 |
| Overshoot margin,percentage points | 0.831672765188475 | 0.00458310873332635 | Continuous margin narrow |
| Peak headroom,V | 0.0127245933073836 | 7.01215636198516e-05 | Both>1e-6 numerical headroom |
| Settling,s | 0.0393843295040084 | 0.0499918433906416 | Both strictly<.05 |
| Settling deadline margin,s | 0.0106156704959916 | 8.15660935835766e-06 | Continuous≈8.16 μs |
| Last outward band crossing | none | none | Initially below band; no subsequent exit |
|10–90% rise,s|0.0255343862231679|0.0334539539710188|Same reference thresholds|
|Final output,V|1.53|1.53|Analytical equilibrium1.53|
|Linear stability|rho=0.787662889162849|All roots LHP|Nominal local stability established|
|Raw minimum,V|0.640273037088054|1.21211192106738|No clipping|
|Raw maximum,V|3.13659632743388|3.1368596639945|Below+5|
|Maximum absolute applied effort,V|3.13659632743388|3.1368596639945|Inside±5|
|Saturation intervals|none|none|Nominal only|
|Permanent future band retention|Discrete invariant tail bound|Modal exponential tail bound|Numerically verified analytical bounds|

There are only five intervals before.05 s. The sampled response enters the band at.03938433 s and remains there through intersample extrema; it does not rely on the update at.05 s. The continuous result's deadline margin is small; rounding.04999184 to.05 would hide useful information, while calling it a comfortable pass would also mislead.

## Independent paths, tails and numerical precision

1. Search sampled propagation uses scipy matrix exponentials. Verification uses scalar damped-sinusoid propagation and locates every current-zero extremum inside each.01 s interval. Since wd Ts≈.3655<π, there is at most one nontrivial current zero inside an interval. Threshold roots on the resulting monotone segments use brentq xtol1e-13 s. Full parallel scalar/matrix trajectory difference=4.44e-16; one-step maximum difference=2.22e-16.
2. Sampled characteristic polynomial is independently assembled from the ZOH plant transfer function and discrete controller rational functions. Polynomial coefficient discrepancy=8.88e-16. Continuous state-matrix polynomial relative discrepancy=7.77e-13.
3. Continuous dynamics were independently integrated with actual saturation/back-calculation using DOP853, then compared against rational residues and exact event localization. The maximum reported initial ODE/rational voltage difference is about1.2e-12 V. Additional tighter-tolerance, halved-max-step checks are in precision_results.json. No nominal saturation occurs, so the verified linear solution is also the saturated-law solution.
4. Continuous raw extrema include the fast early maximum at about9.169 μs, which a coarse grid missed. The refined maximum3.136859664 V is used above, not the earlier grid-only3.136596327 V. Continuous event bracketing combines an early logarithmic grid with50 μs spacing through2 s; roots are refined to1e-14 s. These are numerical certificates with substantial floating-point headroom, not formal interval-arithmetic proofs.
5. At2 s the sum of magnitudes of remaining continuous output modal terms is 5.13e-17 V and control modal terms 3.62e-17 V. All nonzero poles have negative real parts, so these envelopes decrease forever. Equilibrium control1.53 V is interior to the rails.
6. At5 s the sampled tail is checked by both modal bounds and a scaled discrete Lyapunov invariant. P solves FsᵀP Fs−P=−I, with min eigenvalue 1.0740543 and residual 1.8e-15. Cauchy–Schwarz dual-norm bounds ensure future raw control stays inside rails, allowing unsaturated induction; all intersample output deviations are bounded by 1.49e-14 V. This supports permanent, not merely finite-window, settling in the nominal analytical model.

| Tight ODE maximum step,s | Settling difference from rational,s | Peak difference,V |
|---|---:|---:|
| 0.00025 | 1.704e-14 | -4.663e-15 |
| 0.000125 | 1.704e-14 | -3.331e-15 |

The numerical discrepancies are far below the8.16 μs/70.1 μV continuous margins. Gains rounded to eight significant digits were separately assessed and retain nominal passes: sampled=True, continuous=True. Use full recorded gains for reproducibility; this is not permission to edit the model.

## Saturation, integral behavior and filter sensitivity

The actual clip/back-calculation law was active in every sampled evaluation. For the finalist it never clips: sampled integral ranges from0 to1.56849140768 V and converges to1.53 V. Every AW increment is exactly zero in the computed nominal sequence. This verifies nominal nonactivation, not anti-windup recovery under a disturbance or infeasible command. Kaw20 is preserved; no tuning of Kaw was performed.

DOM removes the reference derivative kick but not measurement-noise amplification. Continuous high-frequency derivative gain KdN≈1372.10651 V/V; total proportional-plus-derivative gain≈1374.15657. A1 mV high-frequency measurement perturbation can therefore demand roughly1.37 V in the continuous linear path. This is a gain illustration, not a measured noise result. Discrete α≈0.00199602581, N Ts≈499.995525; BE derivative approaches a backward difference. Discrete Nyquist derivative gain is2KdN/(2+N Ts)≈5.46660852 V/V. Large continuous N is not equivalent to resolving that bandwidth at100 Hz. Noise spectrum, delay and uncertainty remain untested.

One-at-a-time perturbations are optional robustness diagnostics, not retroactive hard requirements. Four of16 perturbations retain both nominal criteria; these are only the N changes. Every tested±1% and±5% change of Kp,Ki or Kd breaks at least one combined target. This is substantial fragility despite adequate numerical precision.

| Parameter change | Sampled OS,% | Sampled settling,s | Continuous OS,% | Continuous settling,s | Combined pass |
|---|---:|---:|---:|---:|---|
| Kp -5% | 1.83553732 | 0.0420475124468461 | 2.47241476 | 0.0759911530009161 | False |
| Kp -1% | 1.28921436 | 0.0399040446045616 | 2.08155472 | 0.068720047888096 | False |
| Kp +1% | 1.05309126 | 0.073028436378369 | 1.91373911 | 0.120721433291292 | False |
| Kp +5% | 1.53812007 | 0.0794846111268885 | 1.62986857 | 0.128611968513799 | False |
| Ki -5% | 0.408697584 | 0.0801345122593066 | 0.697632278 | 0.132115607545417 | False |
| Ki -1% | 1.02129971 | 0.0731244871216464 | 1.73795837 | 0.120965497552562 | False |
| Ki +1% | 1.31300691 | 0.0390936977716676 | 2.25184465 | 0.0703818002527459 | False |
| Ki +5% | 2.30449915 | 0.0508937523024905 | 3.26742786 | 0.0775832061435266 | False |
| Kd -5% | 2.27008278 | 0.0759450088489948 | 2.19614343 | 0.128616799264414 | False |
| Kd -1% | 1.10317514 | 0.0688906407776162 | 2.03044083 | 0.120384451642804 | False |
| Kd +1% | 1.25947064 | 0.0673275996812687 | 1.96293806 | 0.0502487028649834 | False |
| Kd +5% | 1.63156534 | 0.067635891189254 | 1.85827462 | 0.0512771172334428 | False |
| N -5% | 1.16880072 | 0.0393826310135735 | 1.99450433 | 0.0499929536941701 | True |
| N -1% | 1.16841809 | 0.0393840035092043 | 1.99524175 | 0.0499920564632653 | True |
| N +1% | 1.16823818 | 0.0393846490535581 | 1.99558856 | 0.0499916345446224 | True |
| N +5% | 1.16789898 | 0.0393858664766402 | 1.99624255 | 0.0499908390073243 | True |

## Search limits and unresolved questions

- This is a nominal numerical existence demonstration within a searched positive-gain domain, not a global optimum or robust-feasibility proof. The gain point was obtained from a documented objective, not invented and retroactively justified.
- Search screening used finite horizons/grids; only the final independently localized events and future-tail bounds support the finalist's permanent settling claim. All earlier results remain in separate files, including unsuccessful joint domains and optional-margin removal.
- The high-N branch is restricted to unsaturated feasible trajectories; it does not exhaust nonlinear saturated designs. The broader initial searches did evaluate saturation and AW. No conclusion of infeasibility is drawn for unexplored regimes.
- Very high N and the narrow continuous margins make implementation timing, numerical resolution, noise and component uncertainty important. These diagnostics do not erase the nominal pass, but they prevent a claim of robust engineering suitability.
- Native explicit/native PID equivalence, disturbance behavior, infeasible-command AW recovery and saved-model reproducibility for a controller remain unverified. Open-loop Phase 2 evidence cannot supply those results.

## Updated supplemental project-state handoff

| Item | Disposition |
|---|---|
|Phase 2|CLOSED for identified current model, unchanged limitations|
|Historical continuous PID settling|FAIL .07376186885457478 s preserved|
|Historical continuous PID overshoot|PASS1.6175747991% preserved|
|Rejected fast candidate|Unstable sampled rejection preserved|
|New sampled-only candidates|Nominal analytical passes; continuous counterpart failure disclosed|
|New high-filter finalist|Combined nominal analytical hard criteria satisfied; narrow continuous margin and poor gain sensitivity|
|Model provenance|Two differing hashes retained; unresolved|
|Native controller implementation|Not performed and not approved by this report|
|Overall project|NOT ACCEPTED|

**Exactly one recommended next step:** conduct a focused analytical robustness qualification of this nominally feasible high-filter candidate, addressing its narrow continuous margins and sensitivity before deciding whether it is suitable for isolated native implementation.

This recommendation is an engineering decision based on fragility, not a claim that the stated nominal hard criteria failed. No acceptance threshold has been relaxed or added retrospectively. Stop after this review: no model edits/saves, Simulink execution, gain changes in project files, historical report edits, manifest regeneration or release-package rebuild occurred.

## Reproducibility and file inventory

Use README_REPRODUCE.md. Scripts and outputs are a separate analysis record. JSON results retain full floating-point values; CSV files are analytical state sequences, never native logs. The analysis ZIP is a new reproducibility bundle, not a rebuilt candidate release. SHA256SUMS_ANALYSIS.txt identifies all included files other than itself. Original evidence archives remain unchanged.

Preservation checks in preservation_check.json compare the prior review, Phase 2 records and original candidate ZIP with hashes captured before this search. All comparisons pass. preserved_inputs.json records those identities. Runtime versions and hashes of the new scripts and preregistrations are listed below.

Python3.12.14; NumPy2.3.5; SciPy1.17.0; platformLinux-6.18.55-x86_64-with-glibc2.39.

| Source / preregistration | SHA-256 |
|---|---|
| BOUNDARY_SEARCH_AMENDMENT.md | `aaf4a7d3d8b467b433f8b09168f18ffb4c554cb3877ed21f9855aa22fcb71221` |
| HIGH_FILTER_AMENDMENT.md | `11979058a30dc733b5e15d5891356293850235ef5c1171d6873fa4c2e4954a8f` |
| JOINT_SEARCH_AMENDMENT.md | `62fee061154ea7b45f74b8c40440776ea196eacff112e92f663b6a09a5ec9d67` |
| PREREGISTRATION.md | `41c969b1b7030c12f64b13146f40f6fd44c1962806bf86459c77a854a8f7d7a8` |
| assess_additional_searches.py | `53034ebee4c96b69b72018effa626dc50d66a352c805d486b7abef292c74e581` |
| boundary_search.py | `a99c3d458667f1bedb6607bab6668881f326fd758590eec5caf2ff98ee3735c0` |
| build_report.py | `a8e1c614bcad9c3215672562a34b274d9ec0ac3d634e7bc9dbf5b1b38c2380cc` |
| continuous_screen.cpp | `0b3d4496b68962f5de0bb6959bff9dd29e23c477f2ed47d98f1fb54897ffd45d` |
| final_assessment.py | `7922bbc19b212d48ca361f0b5b929b87285a6783c4398a1e6c051b15c79cdfdf` |
| high_filter_search.py | `cf12f233e55f100464205f2211651af34ccdd4bf3f90d19a621fb3502f5a0943` |
| joint_search.py | `8ad24aba08d4bf487bd1aa0d0ffb7ab6f3c59029e67f0e4084e38ac376963f76` |
| precision_check.py | `f6f9df4b1a4fc60d627caad0ea146d490e37ca8ea8ec6d3462670307d97037b1` |
| synthesize.py | `87d227a188f0c5ba2e7871d1a6973a36c3fd2f0dfe5f8246bc36aef9513a90d4` |
| validate.py | `aa2bee19c8c61a862bce640b73a0dbfd7a68d60ec37db4c17e57f525abd67732` |
