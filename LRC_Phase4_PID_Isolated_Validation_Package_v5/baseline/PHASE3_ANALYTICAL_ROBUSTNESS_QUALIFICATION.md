# PHASE 3 — ANALYTICAL ROBUSTNESS QUALIFICATION

Date: 2026-10-25. Separate supplemental record. Fixed candidate; no redesign.

## Executive finding

**The candidate is not sufficiently qualified to proceed to isolated native implementation on the available robustness evidence.** This is an engineering readiness judgment, not a reversal of its nominal analytical pass or a proof of architectural infeasibility. The nominal parameters and zero-delay/noiseless assumptions produce passing predictions, but the combined performance is not retained over either diagnostic plant grid, is strongly degraded by a one-sample delay, and is vulnerable to high-frequency measurement noise in the continuous implementation.

No source-defined component-tolerance envelope or sensor-noise spectrum was found. Therefore the plant/noise screens below are explicitly diagnostic; they are not retroactive contractual acceptance tests. No tested nonzero tolerance box has been qualified, and measured hardware uncertainty/noise is unavailable to justify a tighter deployment envelope. The evidence supports withholding implementation readiness, not asserting that the hardware necessarily has the tested perturbations.

## A. Verified baseline and preserved history

Bundle: PHASE3_Constrained_Synthesis_Analysis_20261024.zip.

Expected and measured SHA-256:
`2f7d70d1c35507728cdb2398d0669d3a508466110393cac94e38453d523bb779`.

ZIP integrity passes. All42 entries of SHA256SUMS_ANALYSIS.txt match the actual archived bytes. Prior closure/addenda, the previous Phase 3 review and the original candidate ZIP match the preservation hashes carried in the bundle. End-of-work preservation checks also pass. Neither original nor native manifest was regenerated.

Current audited open-loop model:
`3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1`.

Original native-manifest model entry:
`f1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f`.

The difference remains unexplained. This report does not claim original-model continuity. Phase 2 remains CLOSED with its recorded provenance and unavailable-cursor limitations. Overall project remains NOT ACCEPTED.

Historical candidate results remain untouched: continuous overshoot1.6175747991% PASS and settling0.07376186885457478 s FAIL against strict<0.05 s; sampled prediction≈4.67597% and0.17337 s; previously rejected fast candidate sampled radius≈1.02376446. The new candidate's earlier gain-perturbation sensitivity is retained and was not rerun or reclassified as robust acceptance.

Fixed candidate throughout this qualification:

| Quantity | Value |
|---|---:|
|Kp|2.050062959107108|
|Ki|40.633656994693226 s⁻¹|
|Kd|0.027442375755061164 s|
|N|49999.55245385603 s⁻¹|
|Ts|0.01 s|
|Kaw|20 s⁻¹|
|Applied voltage rails|−5,+5 V|
|Reference|1.53 V|

**Evidence classes:** SOURCE = master, archived CTMS PDF and controller source; HISTORICAL ANALYTICAL = preserved prior predictions; DERIVED = all new calculations here; DIAGNOSTIC ASSUMPTION = uncertainty envelopes, injected noise, quantizer idealization and delay; NATIVE = only the already closed Phase 2 evidence. No MATLAB/Simulink was executed. No model or project-script gains were changed.

Sources inspected: constrained-synthesis review, its preregistration and three amendments, prior PHASE3_ANALYTICAL_REVIEW_20261024.md, master requirements, source recurrence and archived CTMS reference. Master SHA-256 remains `c9a36231db3f0e50b1c1d4d29a394f3b431a501c29011d60fc19a246fbebb759`. Source recurrence is init_lrc_pid.m lines287–328; definitions include Kaw20. Readable source excerpts are retained in source_requirement_scan.json.

## B. Requirements and diagnostic assumptions

The master gives nominal Rtotal50 ohm,L1 H,C510 μF and numerical/model-validation tolerances, but no bounded physical R/L/C uncertainty envelope. The archived CTMS reference discusses component variation qualitatively on p10. Its pp7–8 specify10-bit,0–5 V acquisition with scaling5/1023 V and sample time0.01 s. Those are genuine reference facts; they do not establish that the candidate PID model contains an ADC or that a particular sensor is selected.

No applicable sensor noise PSD/RMS, analog bandwidth, anti-alias filter or controller-specific resolution requirement was found. The source's numerical tolerances are not component manufacturing tolerances. Diagnostic noise amplitudes are not measured sensor data.

Plant cases: independently choose each of Rtotal,L,C at low,nominal,high for ε=.01 and.05. Each envelope has27 entries, including all8 corners; the two grids share the nominal point, giving53 unique physical triples. Gains are never retuned. Rtotal is varied as an aggregate; no additional independent resistor/ESR split is assumed.

Noise cases start at the nominal equilibrium to isolate noise-induced variation from a reference transient. Both P and I see error r−(y+n); D acts on measurement y+n. Noise never enters the reference. Sampled cosine tests use1 and5 mV peak at1,10,25,49,50 Hz; cosine avoids the degenerate zero-valued sin(πk) at Nyquist. Sampled random noise is uniform±A at100 Hz, NumPy PCG64 seed20261025,20 s with first5 s discarded. Continuous sinusoids use1 and5 mV peak at1,10,50,1000,8000,50000 Hz. Continuous random noise is uniform±A, held at1000 Hz with the same seed,1 s with first.2 s discarded. The two random streams have different hold rates and are not interchangeable physical sensor models. Ideal step edges contain high frequencies; this is bounded piecewise-constant noise, not bandlimited or white noise.

An additional sampled quantizer diagnostic rounds the measured voltage to q=5/1023≈4.887586 mV, without imposed random noise. Quantization error is endogenous, not independent additive white noise. This tests a source-inspired hypothetical measurement chain, not an observed ADC.

## C. Equations, events and future-tail assessment

For each plant:

`A=[[-Rtotal/L,−1/L],[1/C,0]], B=[1/L,0]ᵀ`, x=[i,y].

`P(s)=LC s²+Rtotal C s+1`.

With a=LC,b=Rtotal C, negative feedback gives

`Q(s)=a s⁴+(b+aN)s³+(1+bN+Kp+KdN)s²+[N(1+Kp)+Ki]s+KiN`.

The DOM reference numerator is `(Kp s+Ki)(s+N)`. Neither ideal-PID pole matching nor exp(continuous roots·Ts) is used for the sampled system.

Let α=1/(1+N Ts),β=KdNα,mk=yk+nk. Baseline recurrence:

`vk=Kp(r−mk)+Ik−β(mk−fprev,k)`;
`uk=clip(vk,−5,5)`;
`I(k+1)=Ik+Ts[Ki(r−mk)+Kaw(uk−vk)]`;
`fprev,(k+1)=α fprev,k+(1−α)mk`.

Exact ZOH plant propagation is `x(k+1)=Ad xk+Bd uk`, using matrix exponentials for each perturbed plant. Scalar damped-sinusoid propagation independently cross-checks each step. At fixed u within an interval, i(τ) is an exponentially decaying sine/cosine combination. Its zero crossings determine output extrema. All tested plants satisfy wd Ts<π, so at most one nontrivial interior extremum occurs per interval. Threshold roots on monotone segments use brentq1e-13 s. Settling means the last inward band crossing followed by permanent retention, not first entry or five sample endpoints.

Continuous responses use rational residues with derivative-root localization on a100 μs bracket grid and extra logarithmically spaced early points. Raw-control extrema and decreasing modal tail bounds establish no clipping for every tested plant; thus these linear solutions also satisfy the actual saturated/back-calculation equations, whose correction is zero in these cases. Nonlinear Radau spot-checks independently verify nominal and worst-case plants.

Continuous horizon2 s and sampled horizon5 s are followed by analytical tail envelopes. Continuous residue magnitudes multiplied by exp(Re(p)t) bound future deviations. Sampled modal envelopes bound both future raw input and all intersample outputs; when inside the rails, induction validates the unsaturated state matrix forever. These are floating-point numerical analytical certificates, not formal interval-arithmetic proofs. All tested step cases have verified tails. Persistent-noise cases are finite-window diagnostics and are not assigned permanent-settling claims.

OS is100·max(peak−1.53,0)/1.53. Rise is first10–90% reference crossing. All step times are elapsed from t=0. Band is[1.4994,1.5606] V; strict limits remain OS<2%,settling<.05 s,stable continuous roots or sampled radius<1,correct equilibrium tracking and inclusive applied rails. Finite-horizon terminal error is reported separately from asymptotic equilibrium error.

## D. Plant-uncertainty findings

| Diagnostic grid | Continuous criteria met | Sampled criteria met | Both met | Stable cases, each implementation |
|---|---:|---:|---:|---:|
| ±1% | 3/27 | 15/27 | 3/27 |27/27|
| ±5% | 1/27 | 7/27 | 1/27 |27/27|

These counts describe a finite diagnostic grid, not the fraction or probability of a continuous uncertainty box that is acceptable. Even a passing grid would not by itself certify every interior point. Here failed grid points already preclude qualifying the complete tested box.

All step cases remain stable, converge to y=1.53 V at equilibrium and avoid clipping. Performance, not instability or actuator saturation, is the dominant plant-uncertainty failure. Small parameter changes shift the balance between poles, zeros and modal residues; they cause late lower-band excursions or excessive overshoot despite the nominal response having tiny margins.

Worst cases (levels ordered Rtotal,L,C; −/0/+ mean low/nominal/high):

| Envelope | Implementation | Worst OS,% / levels | OS margin,pp | Worst settling,s / levels | Settling margin,s |
|---|---|---|---:|---|---:|
| ±1% | continuous | 2.32183021 / −,+,+ | -0.321830209 | 0.122912684935 / −,+,− | -0.0729126849 |
| ±1% | sampled | 1.4645755 / −,+,+ | 0.535424499 | 0.0737098673384 / −,−,− | -0.0237098673 |
| ±5% | continuous | 3.70894316 / −,+,+ | -1.70894316 | 0.132901922992 / −,+,+ | -0.082901923 |
| ±5% | sampled | 4.03870579 / −,+,+ | -2.03870579 | 0.0816127904609 / −,+,− | -0.0316127905 |

Every case is listed below. S=settling failure,O=overshoot failure; a dash means both tracking criteria met. All listed cases have stable poles, correct equilibrium and no saturation. Full JSON additionally records poles, peak times, last band exits, final errors, control extrema and tail bounds.

| Envelope | R,L,C levels | Continuous OS,% | Continuous settling,s | Fail | Sampled OS,% | Sampled settling,s | Fail |
|---|---|---:|---:|---|---:|---:|---|
| ±1% | −,−,− | 1.734924 | 0.119468473 | S | 1.123855 | 0.0737098673 | S |
| ±1% | −,−,0 | 1.86505 | 0.117758345 | S | 1.145639 | 0.0722065868 | S |
| ±1% | −,−,+ | 1.994119 | 0.0499914248 | — | 1.168098 | 0.0393825408 | — |
| ±1% | −,0,− | 1.896966 | 0.12129354 | S | 1.095273 | 0.0736724068 | S |
| ±1% | −,0,0 | 2.027715 | 0.120120275 | O,S | 1.115798 | 0.0716076447 | S |
| ±1% | −,0,+ | 2.157389 | 0.118338011 | O,S | 1.14099 | 0.0392173404 | — |
| ±1% | −,+,− | 2.060202 | 0.122912685 | O,S | 1.165825 | 0.0735259978 | S |
| ±1% | −,+,0 | 2.191561 | 0.122044743 | O,S | 1.315894 | 0.038891844 | — |
| ±1% | −,+,+ | 2.32183 | 0.120885608 | O,S | 1.464576 | 0.0390782635 | — |
| ±1% | 0,−,− | 1.705274 | 0.113977539 | S | 1.174512 | 0.0724909371 | S |
| ±1% | 0,−,0 | 1.835023 | 0.0501938842 | S | 1.198428 | 0.0704563955 | S |
| ±1% | 0,−,+ | 1.963725 | 0.0502323144 | S | 1.223075 | 0.0397518867 | — |
| ±1% | 0,0,− | 1.86505 | 0.117758345 | S | 1.145639 | 0.0722065868 | S |
| ±1% | 0,0,0 | 1.995417 | 0.0499918434 | — | 1.168327 | 0.0393843295 | — |
| ±1% | 0,0,+ | 2.12472 | 0.0691339911 | O,S | 1.191391 | 0.0395625374 | — |
| ±1% | 0,+,− | 2.026082 | 0.12009933 | O,S | 1.116101 | 0.0716165028 | S |
| ±1% | 0,+,0 | 2.157055 | 0.118283103 | O,S | 1.139244 | 0.0392206912 | — |
| ±1% | 0,+,+ | 2.286949 | 0.0709854799 | O,S | 1.289083 | 0.0394036607 | — |
| ±1% | +,−,− | 1.677826 | 0.0504028634 | S | 1.227005 | 0.0711636154 | S |
| ±1% | +,−,0 | 1.807211 | 0.0504357525 | S | 1.253073 | 0.0679118809 | S |
| ±1% | +,−,+ | 1.93556 | 0.0504733706 | S | 1.279932 | 0.0401388727 | — |
| ±1% | +,0,− | 1.835312 | 0.0501914662 | S | 1.197891 | 0.0704758214 | S |
| ±1% | +,0,0 | 1.965312 | 0.0502303153 | S | 1.222767 | 0.0397498374 | — |
| ±1% | +,0,+ | 2.09426 | 0.0690648985 | O,S | 1.248079 | 0.0399223659 | — |
| ±1% | +,+,− | 1.994119 | 0.0499914248 | — | 1.168098 | 0.0393825408 | — |
| ±1% | +,+,0 | 2.12472 | 0.0691339911 | O,S | 1.191391 | 0.0395625374 | — |
| ±1% | +,+,+ | 2.254254 | 0.0710826984 | O,S | 1.214889 | 0.039741183 | — |
| ±5% | −,−,− | 0.6764105 | 0.124684048 | S | 1.000765 | 0.076786916 | S |
| ±5% | −,−,0 | 1.332619 | 0.122300919 | S | 1.06735 | 0.0758712384 | S |
| ±5% | −,−,+ | 1.962926 | 0.115183534 | S | 1.162611 | 0.0700383212 | S |
| ±5% | −,0,− | 1.505286 | 0.12895129 | S | 1.005377 | 0.0790907649 | S |
| ±5% | −,0,0 | 2.178964 | 0.12812145 | O,S | 1.73543 | 0.077540341 | S |
| ±5% | −,0,+ | 2.824702 | 0.126598842 | O,S | 2.447642 | 0.0522048557 | O,S |
| ±5% | −,+,− | 2.359302 | 0.132738723 | O,S | 2.622586 | 0.0816127905 | O,S |
| ±5% | −,+,0 | 3.048971 | 0.132892916 | O,S | 3.346025 | 0.0792696728 | O,S |
| ±5% | −,+,+ | 3.708943 | 0.132901923 | O,S | 4.038706 | 0.0597209728 | O,S |
| ±5% | 0,−,− | 0.5623218 | 0.11478878 | S | 1.178945 | 0.0742940724 | S |
| ±5% | 0,−,0 | 1.208055 | 0.0511259118 | S | 1.313366 | 0.0718055953 | S |
| ±5% | 0,−,+ | 1.829334 | 0.0512385607 | S | 1.465997 | 0.0414355614 | — |
| ±5% | 0,0,− | 1.332619 | 0.122300919 | S | 1.06735 | 0.0758712384 | S |
| ±5% | 0,0,0 | 1.995417 | 0.0499918434 | — | 1.168327 | 0.0393843295 | — |
| ±5% | 0,0,+ | 2.631623 | 0.0754039391 | O,S | 1.55546 | 0.0402609048 | — |
| ±5% | 0,+,− | 2.135994 | 0.127859744 | O,S | 1.65281 | 0.0774564245 | S |
| ±5% | 0,+,0 | 2.814209 | 0.126096705 | O,S | 2.402738 | 0.0520340633 | O,S |
| ±5% | 0,+,+ | 3.46401 | 0.079640597 | O,S | 3.119191 | 0.0594212929 | O,S |
| ±5% | +,−,− | 0.5042155 | 0.0524861856 | S | 1.396668 | 0.0717053743 | S |
| ±5% | +,−,0 | 1.141128 | 0.0524001455 | S | 1.596717 | 0.0674889591 | S |
| ±5% | +,−,+ | 1.755032 | 0.0524911393 | S | 1.811701 | 0.043912332 | — |
| ±5% | +,0,− | 1.212904 | 0.0510618916 | S | 1.300095 | 0.0720181934 | S |
| ±5% | +,0,0 | 1.866665 | 0.0511850976 | S | 1.458277 | 0.0413530753 | — |
| ±5% | +,0,+ | 2.495162 | 0.0769298647 | O,S | 1.637068 | 0.0420067789 | — |
| ±5% | +,+,− | 1.962926 | 0.115183534 | S | 1.162611 | 0.0700383212 | S |
| ±5% | +,+,0 | 2.631623 | 0.0754039391 | O,S | 1.55546 | 0.0402609048 | — |
| ±5% | +,+,+ | 3.273165 | 0.0814210048 | O,S | 2.375959 | 0.0584959458 | O,S |

Across all plant-grid step cases, maximum absolute applied effort=3.13689169337 V, leaving at least1.86310830663 V rail headroom. Maximum terminal output-error magnitude=1.954e-14 V. These good stability/control-effort results do not compensate for the transient failures. In the±1% grid the combinations meeting both are(−,−,+),(0,0,0),(+,+,−); in the±5% grid only(0,0,0) meets both. These isolated points do not define a qualified tolerance envelope.

## E. Measurement-noise transfer derivation

For unsaturated continuous operation, define the feedback controller

`Cf(s)=Kp+Ki/s+KdN s/(s+N)`.

Because the noise enters the measured output, not the reference,

`U/n=−Cf/(1+G Cf)`, `Y/n=−G Cf/(1+G Cf)`.

Y is the true capacitor voltage. Measured output Y+n would have a different transfer. DOM eliminates reference derivative kick, not measurement-noise differentiation. AW is zero in this linearization; clipping requires the nonlinear equations.

For sampled operation,

`Cf(z)=Kp+Ki Ts/(z−1)+β(z−1)/(z−α)`;
`Gd(z)=[0,1](zI−Ad)^−1 Bd`;

`U/n=−Cf(z)/(1+Gd(z)Cf(z))`, `Yk/n=−Gd(z)Cf(z)/(1+Gd(z)Cf(z))`.

This follows from FE integration I(z)/e(z)=Ki Ts/(z−1) and BE filter fprev(z)/m(z)=(1−α)/(z−α). A separate state-space derivation uses U=[0,−Kp−β,1,β], γ=−Kp−β and

`Bn=[Bd γ;−Ts Ki;1−α]`;
`U/n=γ+U(zI−F)^−1 Bn`, `Yk/n=[0,1,0,0](zI−F)^−1 Bn`.

The two sampled transfer calculations agree to9.44e-15 absolute on the sweep. DC limits are−1 for both true output and control; constant measurement bias shifts true equilibrium output by the negative bias. Frequency-response plots/tables are linear and do not imply saturation immunity.

Sampled sweep0–50 Hz in.005 Hz increments finds maximum noise-to-control magnitude≈8.42266 V/V near22.98 Hz and noise-to-sample-output magnitude≈1.25536 near14.81 Hz. At50 Hz, |U/n|=7.541982731,|Yk/n|=0.03124077887. The output transfer applies at sample instants only. Time-domain tables below include true intersample output, integrated by8-point Gaussian quadrature per held-input interval, with exact extrema checked separately.

Continuous high-frequency control gain tends to Kp+KdN=1374.15656898 V/V. Filter time constant is about20 μs and cutoff≈7957.68 Hz. Thus a small high-frequency sensor voltage can create large actuator variation while the second-order plant strongly attenuates output ripple. Neither100 Hz sampling nor a small plant solver step resolves an8 kHz physical measurement band. Above50 Hz, analog signals alias unless an actual anti-alias chain prevents it; none is specified here. In particular ideal cosine noise exactly at8000 or50000 Hz would sample as a DC sequence at100 Hz, not as the continuous experiment's waveform. The high-frequency continuous and below-Nyquist sampled studies are separate diagnostics.

## F. Bounded-noise diagnostic results

RMS and peak deviations are about the noiseless equilibrium u=y=1.53 V, and therefore include bias. They are not just AC standard deviations. Sampled control is held, output RMS includes intersample behavior, and quantizer statistics use its endogenous error. Nyquist cosine has RMS equal to its peak amplitude, not peak/√2.

| Sampled case | Input peak,mV / Hz | Control RMS,V | Control peak deviation,V | Output RMS,V | Output peak deviation,V | Saturated duration,s |
|---|---|---:|---:|---:|---:|---:|
| cosine | 1 / 1 | 0.0006849452 | 0.0009685205 | 0.0006897444 | 0.0009754549 | 0 |
| cosine | 1 / 10 | 0.001465335 | 0.002016827 | 0.0007602862 | 0.001076994 | 0 |
| cosine | 1 / 25 | 0.005915668 | 0.007162696 | 0.0004348345 | 0.0005950309 | 0 |
| cosine | 1 / 49 | 0.00533375 | 0.007542452 | 9.650579e-05 | 0.0001870557 | 0 |
| cosine | 1 / 50 | 0.007541983 | 0.007541983 | 0.0001359516 | 0.0001866864 | 0 |
| cosine | 5 / 1 | 0.003424726 | 0.004842603 | 0.003448722 | 0.004877274 | 0 |
| cosine | 5 / 10 | 0.007326675 | 0.01008413 | 0.003801431 | 0.00538497 | 0 |
| cosine | 5 / 25 | 0.02957834 | 0.03581348 | 0.002174172 | 0.002975155 | 0 |
| cosine | 5 / 49 | 0.02666875 | 0.03771226 | 0.000482529 | 0.0009352786 | 0 |
| cosine | 5 / 50 | 0.03770991 | 0.03770991 | 0.000679758 | 0.0009334322 | 0 |
| random | 1 / 0 | 0.003829222 | 0.009707572 | 0.0004302425 | 0.001281122 | 0 |
| random | 5 / 0 | 0.01914611 | 0.04853786 | 0.002151212 | 0.006405612 | 0 |
| quantization | 0 / 0 | 0.005150471 | 0.02091589 | 0.00148279 | 0.002334205 | 0 |

Quantization row's0 input amplitude means no added random/sinusoidal noise, not zero quantization error. The observed error is bounded by approximatelyq/2=2.443793 mV. The diagnostic produces a small persistent output variation; it is not evidence that the existing model implements a10-bit sensor.

For unsaturated continuous sinusoids, exact periodic transfer amplitudes give RMS=amplitude/√2 and establish that raw effort remains inside rails. For clipped sinusoids the full saturated nonlinear equations are integrated, with back-calculation. The report uses the half-step refined results for clipped cases. Measurement windows: continuous clipped sinusoids.5–1 s; random.2–1 s; sampled5–20 s. These windows quantify the stated experiments and do not establish arbitrary-noise worst-case behavior.

| Continuous case | Input peak,mV / Hz | Control RMS,V | Control peak deviation,V | Output RMS,V | Output peak deviation,V | Saturated duration,s |
|---|---|---:|---:|---:|---:|---:|
| cosine | 1 / 1 | 0.0006793078 | 0.0009606863 | 0.00068418 | 0.0009675766 | 0 |
| cosine | 1 / 10 | 0.001081132 | 0.001528952 | 0.0005702773 | 0.0008064939 | 0 |
| cosine | 1 / 50 | 0.006179935 | 0.008739748 | 0.0001236453 | 0.0001748608 | 0 |
| cosine | 1 / 1000 | 0.121285 | 0.1715228 | 6.023999e-06 | 8.519221e-06 | 0 |
| cosine | 1 / 8000 | 0.6892681 | 0.9747723 | 5.349072e-07 | 7.56473e-07 | 0 |
| cosine | 1 / 50000 | 0.9596238 | 1.357113 | 1.906475e-08 | 2.696163e-08 | 0 |
| cosine | 5 / 1 | 0.003396539 | 0.004803431 | 0.0034209 | 0.004837883 | 0 |
| cosine | 5 / 10 | 0.005405662 | 0.007644761 | 0.002851387 | 0.00403247 | 0 |
| cosine | 5 / 50 | 0.03089968 | 0.04369874 | 0.0006182263 | 0.000874304 | 0 |
| cosine | 5 / 1000 | 0.6064248 | 0.8576142 | 3.011999e-05 | 4.25961e-05 | 0 |
| cosine | 5 / 8000 | 3.121402 | 4.739883 | 0.1296525 | 0.129656 | 0.13 |
| cosine | 5 / 50000 | 3.827631 | 6.347025 | 0.4250369 | 0.4250376 | 0.1775 |
| random | 1 / 0 | 0.1112185 | 2.640603 | 9.462525e-05 | 0.0002739459 | 0 |
| random | 5 / 0 | 0.4662275 | 6.53 | 0.003020349 | 0.005324828 | 0.00340525 |

The1 mV,50 kHz continuous case requests approximately1.36 V peak control variation, even though true output RMS is only about19 nV. Output smoothness alone would therefore be a misleading noise assessment.

At5 mV and high frequencies, asymmetric clipping and the back-calculation correction introduce a negative mean tracking bias. The large output RMS in those rows is mostly bias, not an8 kHz/50 kHz capacitor ripple. Bounded random noise can instead create brief large derivative spikes and both-rail clipping. Those effects are consequences of the stated diagnostic waveforms and controller law, not measured hardware behavior.

Refined clipped-case extrema and means:

| Case | Raw min/max,V | Applied min/max,V | Mean output deviation,V | Mean control deviation,V |
|---|---|---|---:|---:|
| random 5mV 0Hz | -11.667629 / 14.532011 | -5 / 5 | -0.0028122219 | -0.002894392 |
| cosine 5mV 8000Hz | -3.2098829 / 6.5372175 | -3.2098829 / 5 | -0.12965248 | -0.12968667 |
| cosine 5mV 50000Hz | -4.8170248 / 8.7540242 | -4.8170248 / 5 | -0.42503695 | -0.42504241 |

All applied voltages remain bounded by the explicit rails. Rail contact is a diagnostic observation, not an out-of-range voltage violation. No formal noise PASS/FAIL is assigned because no applicable noise limit is specified. Small sampled-noise results cannot certify unknown sensor bandwidth, aliasing, noise levels or quantization behavior.

## G. One-sample computational-delay sensitivity

The zero-delay baseline is unchanged. Introduce a queued raw command qk=v(k−1), initialq0=0, apply uk=clip(qk), and update q(k+1)=vk. The source does not define how a new computational-delay mechanism would timestamp its tracking feedback. To avoid hiding this ambiguity, two diagnostic schedules are evaluated:

1. **Literal source tracking:** integral correction remains Kaw(actual uk−current vk). Even without clipping, the difference can be nonzero because the applied command is one sample old. This preserves the source's literal external tracking signal relationship in the delayed diagnostic.
2. **Timestamp-aligned clipping:** integral correction is Kaw(uk−qk). This compares the applied voltage with the raw command that generated it; correction is zero without clipping. It is explicitly a different diagnostic scheduling interpretation, not a silent replacement of the baseline law.

In augmented state[i,y,I,fprev,q], let Ud=[0,−Kp−β,1,β,0]. Fdelay top rows are[Ad,0,0,Bd], filter row[0,1−α,0,α,0], queue rowUd. Integral row starts[0,−TsKi,1,0,0]; literal tracking addsTsKaw(e5ᵀ−Ud), whereas aligned clipping adds zero in the unsaturated linearization. This derivation includes the tracking effect rather than treating every delayed system as a pure z⁻¹ multiplier with unchanged integral dynamics.

| Diagnostic | Spectral radius | OS,% | Settling,s | Last band exit,s | Peak applied,V | Saturation,s |
|---|---:|---:|---:|---:|---:|---:|
| source_tracking | 0.914528897725 | 31.21922707 | 0.370610357456 | 0.358473786581 | 3.136596327 | 0 |
| aligned_clipping | 0.985006822979 | 50.87844874 | 2.19866043989 | 2.19298765586 | 3.82702567 | 0 |

Both delayed diagnostic equilibria remain linearly stable, but both fail the original overshoot and settling limits by large margins. They do not prove instability, and neither proves that the existing native model has a delay. Literal tracking has a nonzero correction due to lag even without saturation. Aligned clipping has no correction in this step case. The aligned case has a5 s residual of about0.452 mV while its stable equilibrium error is zero; that finite-time residual is not misreported as an asymptotic offset. Tail bounds support the reported eventual band retention.

## H. Numerical verification, limitations and reproducibility

The nominal point reproduces the preceding bundle's settling results to within1e-10 s; this checks generalized-plant code without replacing the historical results. All perturbed linear continuous responses were checked for raw-control rail clearance. Independent nonlinear Radau comparisons at nominal and selected worst-case plants give:

| Rtotal,ohm | L,H | C,F | Max nonlinear-ODE/rational output difference,V |
|---:|---:|---:|---:|
|47.5|1.05|0.0005355000000000001|2.618e-12|
|49.5|1.01|0.0005049000000000001|3.294e-12|
|50.0|1.0|0.00051|3.803e-12|

Continuous clipped-noise calculations use RK4 with step no greater than1 μs and at least100 steps per sinusoidal period, then halve the step for stress cases. RMS integration is trapezoidal within smooth intervals and respects random-noise jumps. An initial left-rectangle quadrature sensitivity was detected and corrected before this report. The original and refined final calculations are retained in noise_results.json; no earlier project record was edited.

| Stress case | Control RMS change on halving step,V | Output RMS change,V |
|---|---:|---:|
|random 0Hz|-2.8692e-05|4.5247e-08|
|cosine 8000Hz|6.6052e-06|-1.9145e-05|
|cosine 50000Hz|-0.00019054|-4.9064e-05|

Separate Radau versus refined RK4 comparison for a clipped8 kHz case over.002 s gives final-state absolute differences[i,y,I,f]=[1.3996765480580459e-08, 2.7611414932238176e-08, 3.0330714118065316e-07, 2.706979151945177e-08]. This is a local independent implementation check, not an assertion of identical full-window nonlinear traces. Reported noise values are engineering diagnostics at the shown convergence precision; the small temporal differences do not change the clipping or readiness conclusion.

Limitations: finite uncertainty grids are not continuous-box proofs; bounds assume the nominal second-order plant structure without unmodelled parasitics; arbitrary stochastic spectra, bias, jitter, extra delays and parameter correlation are not characterized; no hardware uncertainty/noise was measured; no native block scheduling or controller equivalence was observed. Noise cases around equilibrium do not characterize all step-plus-noise interactions. No new controller was searched for, optimized or proposed. Optional diagnostic failures do not erase nominal source-criterion passes.

Python3.12.14,NumPy2.3.5,SciPy1.17.0; float64. Random seed20261025. Full equations, scripts, parameter grids and machine-readable outputs accompany this report; README_REPRODUCE.md supplies commands. These are analytical calculations, never substitute native logs. The new checksum manifest applies only to this supplemental analysis.

## Final decision

**Decision 2: The candidate is not sufficiently qualified to proceed to isolated native implementation.** Dominant mechanisms are the very small continuous performance margins under plant variation, substantial transient degradation with a one-sample computational delay, and continuous high-frequency noise amplification leading to clipping and back-calculation-induced bias in the specified diagnostics.

This is a defensible readiness rejection under the requested robustness review, not a claim that the master specified±1%/±5% robustness, that the hardware has5 mV broadband noise, or that no PID architecture can work. No robust operating envelope has been established from the available physical evidence. The previously established nominal analytical pass remains intact. Native equivalence, hardware suitability and overall project acceptance remain unclaimed. No Simulink execution, model modification/save, PID implementation, gain change, historical-manifest regeneration or candidate-release rebuild occurred. Stop here.
