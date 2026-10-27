# Phase 3 analytical PID design and feasibility review

Date: 2026-10-24. Supplemental record; previous records are not superseded or rewritten.

## A. Executive disposition

**Analytical audit completed; controller design is NOT READY for implementation. Overall candidate remains NOT ACCEPTED.** Phase 2 remains formally CLOSED for its explicitly identified open-loop model, with its disclosed limitations. This review establishes why the historical PID fails, verifies its actual filtered poles, and identifies an additional sampled-performance failure. It does not establish an acceptable replacement PID. The unresolved task is constrained controller synthesis, not additional open-loop validation.

No MATLAB/Simulink execution was performed in this review. New results below are evaluations of rational response formulas, polynomial roots and exact linear state-transition matrices in Python/NumPy/SciPy. These are analytical predictions, not native simulation measurements. The original scripts were read, not executed. New working files are confined to a separate phase3_analysis directory.

**Current Phase 2 model SHA-256:**
`3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1`

**Original native-manifest entry:**
`f1f32172e7970712af4bbe7060c71918eaea45cc59ebef1fa60f26dcfaf03c2f`

The cause of this difference remains unknown. No continuity with the originally manifested model is asserted. Neither this analysis nor the earlier reproduction logs resolves that provenance exception. The original manifest remains unchanged. Original interactive Scope traces are unavailable; the manual cursor cross-check was not performed and remains a disclosed, nonblocking Phase 2 procedural limitation.

## Evidence classes and governing sources

- **SOURCE:** master specification §§7,10–13,17; original source code and stored results read from the preserved candidate ZIP. The complete master was recovered previously and its design requirements were checked again here.
- **HISTORICAL ANALYTICAL:** values stored in evidence/analytical_results.json, not native controller measurements.
- **DERIVED:** independent calculations in this review, under the assumptions stated below.
- **DESIGN ASSUMPTION:** nominal components, zero initial states, zero load, ideal voltage actuator within rails, noiseless measurement, no computational delay, step aligned with a controller update, and exact ZOH plant propagation for the sampled analysis. These do not certify real hardware or model scheduling.
- **NATIVE EVIDENCE:** the previously audited Phase 2 open-loop Case A/B results and fresh-process records, as reconciled by the formal closure record. No native closed-loop PID evidence exists in the reviewed records.

Continuity order: PHASE2_RECONCILED_STATUS_ADDENDUM_SCOPE_REVIEW.md → PHASE2_TRACE_AVAILABILITY_AND_REQUIREMENT_CORRECTION.md → PHASE2_FORMAL_CLOSURE_RECORD_20261024.md. The correction and formal closure resolve the earlier cursor-related PENDING disposition; they do not rewrite the original matrices. The fresh-process six PASS comparisons per case remain later evidence supplementing the historical PENDING matrix.

## B. Independent plant and controller derivations

### Physical plant

Kirchhoff's voltage law and capacitor current, at zero load, give

`L di/dt = u − (R+Req)i − y`, `C dy/dt = i`.

Eliminating i gives `LC y'' + (R+Req)C y' + y = u`. With zero initial conditions,

`G(s)=Y/U=1/P(s)`, `P(s)=a s²+b s+1`,

`a=LC=0.000510 s²`, `b=(R+Req)C=0.0255 s`.

The normalized denominator is `s²+50s+1960.78431372549`. Poles are `−25 ± j36.54838318894 s⁻¹`; natural frequency 44.2807442770 rad/s, damping ratio 0.564579489532. DC gain is one V/V. The input is **applied voltage**, not current or the controller's unsaturated requested voltage. At no-load equilibrium, y=u=1.53 V and series current is zero. With a constant capacitor-node load current, steady state instead needs i=Iload and u=y+50 Iload; integral action cannot overcome an infeasible voltage requirement.

### Sign correction

The latest task displays minus signs before all controller terms. Interpreted literally, that is inconsistent with e=r−y and the governing master, §10.3 lines1046–1049, which has **plus** signs. For negative feedback `1+GC=0`, the correct equation is

`s(s+N)P(s) + Kp s(s+N) + Ki(s+N) + Kd N s² = 0`.

Literal subtraction would give constant term −Ki N. With positive Ki,N and positive leading coefficient, the polynomial is negative at zero and positive at sufficiently large positive s, so it has a positive real root. It is not the candidate's negative-feedback characteristic equation. No source or model was edited to make this correction.

### Ideal PID

For `C=Kp+Ki/s+Kd s`, multiplication of `P+C=0` by s gives

`a s³+(b+Kd)s²+(1+Kp)s+Ki=0`.

For desired monic cubic `s³+c2 s²+c1 s+c0`, ideal matching gives Kd=a c2−b, Kp=a c1−1, Ki=a c0. These formulas do not assign the filtered quartic or sampled roots.

### Filtered parallel PID

Expanding every term independently gives:

| Term | Contribution |
|---|---|
| s(s+N)P | a s⁴+(b+aN)s³+(1+bN)s²+N s |
| Kp s(s+N) | Kp s²+Kp N s |
| Ki(s+N) | Ki s+Ki N |
| Kd N s² | Kd N s² |

Therefore

`Q(s)=a s⁴+(b+aN)s³+(1+bN+Kp+KdN)s²+[N(1+Kp)+Ki]s+KiN`.

Kp is V/V (dimensionless), Ki has units s⁻¹, Kd seconds and N s⁻¹ (angular-frequency convention). Every term of the ideal cubic has units s⁻¹; every term of Q has units s⁻². In particular KdN is dimensionless, not a new derivative gain with seconds units.

For desired monic quartic `s⁴+c3 s³+c2 s²+c1 s+c0`, exact filtered matching is

`N=c3−b/a`, `Ki=a c0/N`, `Kp=(a c1−Ki)/N−1`,

`Kd=(a c2−1−bN−Kp)/N`.

N must be positive and the remaining gains must be assessed, not assumed admissible. Specifying N independently fixes the sum of the four pole magnitudes (for real negative poles) to 50+N. Positive coefficients alone do not prove stability; roots must be checked. The usual quartic Hurwitz conditions additionally require d3 d2>d4 d1 and d3 d2 d1>d4 d1²+d3² d0, with positive coefficients d4…d0. Here the explicitly computed negative real roots establish the historical continuous stability.

### Derivative placement changes reference tracking

Source init_lrc_pid.m lines254–260 specifies parallel 2DOF PID with b=1,c=0, i.e. derivative on measurement. The explicit continuous derivative path at lines323–328 has the same transfer relation. Thus

`u=(Kp+Ki/s)(r−y)−[Kd N s/(s+N)]y`,

`Y/R=(Kp s+Ki)(s+N)/Q(s)`.

Derivative on error has the same denominator but adds `Kd N s²` to the numerator. It therefore has a different response. Filtering makes its step kick finite, not absent; derivative on measurement avoids that reference kick. Real closed-loop poles do not guarantee monotonic tracking: reference zeros and modal residues matter.

## C. Historical candidate audit

Source parameters() lines184–196 uses exact **filtered quartic**, not ideal-cubic matching. This is internally consistent with the historical analytical script and report. No coefficient error was found.

| Quantity | Preserved historical candidate | Rejected fast candidate |
|---|---:|---:|
| Kp | 1.2209160924482672 | 6.41914201183432 |
| Ki, s⁻¹ | 33.16839344262296 | 211.84615384615387 |
| Kd, s | 0.024783622571933332 | 0.063409342284934 |
| N, s⁻¹ | 244 | 520 |
| Intended and independently recovered filtered roots, s⁻¹ | −38,−48,−58,−150 | −80,−90,−100,−300 |
| Historical sampled spectral radius | 0.7999839946219525 | **1.0237644606016607** |

Historical Q coefficients, descending powers:

`[0.000510, 0.14994, 14.49012, 575.07192, 8093.088]`.

Rejected Q coefficients:

`[0.000510, 0.2907, 53.652, 4069.8, 110160]`.

Independent roots agree with the intended real roots to floating-point precision. Substituting the historical gains into the **ideal** cubic instead gives `−26.7146919177` and `−35.9403232293 ± j33.8047522895`; these are not the intended filtered poles. This difference is expected, not evidence of a source error.

Historical continuous derivative-on-measurement tracking is

`y(t)=1.53 +9.6028270295e^(−38t)−30.5476316360e^(−48t)+19.6830630388e^(−58t)−0.2682584323e^(−150t)` V.

The opposite-signed residues explain overshoot despite all-real poles. The reference zeros are −Ki/Kp and −N, approximately −27.167 s⁻¹ and −244 s⁻¹; they cannot be ignored in transient design.

| Metric | Stored result | Independent result | Disposition |
|---|---:|---:|---|
| 2% settling, s | **0.07376186885457478** | 0.07376186885457482 | Historical FAIL preserved, target <0.05 |
| Overshoot, % | 1.617574799079941 | 1.617574799079941 | Historical continuous analytical PASS preserved, target <2 |
| 10–90% reference rise, s | 0.0475253374135012 | 0.04752533741350102 | Consistent definition; no invented rise-time target |
| Final value/error, V | 1.53 / 0 | 1.53 / 0 by DC gain | Unsaturated stable nominal prediction |
| Control extrema sampled from analytical formula, V | 1.2463853602 to1.9254578274 | Agreement to rounding | Not a native actuator audit or rigorous extremum bound |

At t=0.05 s, y=1.2779400990 V, error=0.2520599010 V, or 16.4745% of reference. The lower allowed boundary is1.4994 V. The candidate is still far below it. Settling occurs 23.7619 ms late, about47.52% above the permitted deadline. This directly explains the failure without a second-order settling approximation. The positive peak1.5547488944 V remains below1.5606 V; acceptable overshoot cannot compensate for late entry into the band.

Source analytical metrics use reference-based 10% and90% crossings (0.153 and1.377 V). For PID, reference and asymptotic final value coincide. For P-only they do not; a reference-based90% crossing can be undefined. Source run_lrc_verification.m uses sampled crossings and a final-window estimate for overshoot; later native comparisons must account for that finite resolution rather than demand identical last decimals.

The rejected fast set was rejected correctly. Besides its preserved sampled instability, new continuous linear calculations predict about17.8668% overshoot,0.0870229 s settling and maximum requested voltage about9.8953 V. These are new analytical observations, not historical stored metrics. Its initial proportional demand alone is9.82129 V, above+5 V. Saturated behavior is nonlinear and is not represented by those unclipped response values.

## D. Settling-time feasibility

0.05 s spans five Ts=0.01 s intervals. For an aligned step, the control values on intervals [0,.01),…,[.04,.05) must already achieve permanent entry before0.05; an update at0.05 cannot make a strict earlier deadline pass. A smaller continuous-plant solver step does not increase controller update frequency. Intersample excursions count; checking only sample endpoints is insufficient. Misaligned steps or computation delays would add timing burdens not included in the source's zero-delay analysis.

**The deadline is not disproved by sample time or rails alone.** An independent exact nominal reachability calculation supplies a constructive counterexample to that claim. With x=[i,y], A=[[-50,−1],[1/C,0]], B=[1,0]ᵀ, let Ad=exp(A Ts), Bd=∫exp(Aτ)B dτ. Solve

`[Ad²Bd, Ad Bd, Bd] [u0,u1,u2]ᵀ=[0,1.53]ᵀ`, with u0=5.

| Interval, s | Held input, V | End current, A | End output, V |
|---|---:|---:|---:|
| 0–.01 | 5 | .03807888600463 | .41121920012638 |
| .01–.02 | 2.8049560614332454 | .03867728321554 | 1.17671737410187 |
| .02–.03 | −1.5503104510154384 | approximately0 | 1.53000000000000 |
| .03 onward | 1.53 | 0 | 1.53 |

Each interval obeys the rails. For a constant voltage interval, `i(τ)=e^(−25τ)[A0 cos(wdτ)+B0 sin(wdτ)]`, A0=i(0), B0=[u−y(0)−25i(0)]/wd. Checking its zero crossings inside each interval shows no interior reversal; output is monotone and reaches rest at0.03 s. Terminal residual is floating-point scale. It then remains exactly at the reference in the nominal model. This is an analytical, open-loop feedforward reachability witness, **not a proposed PID, not robust tracking, not evidence of saturation recovery, and not a new implementation**. It shows why declaring the target impossible would be unjustified. It does not prove that the prescribed four-parameter PID architecture can realize this sequence and meet all other scenarios.

## E. Sampled controller, filtering and nonlinear limits

### Actual source convention

Source lines302–321 explicitly implements Forward Euler integration and Backward Euler derivative filtering; native-block settings lines258–260 request the same. Let fprev be the previous low-pass measurement, I the integral voltage, α=1/(1+N Ts), β=Kd N α. At each aligned sample:

`u_raw,k = Kp(rk−yk)+Ik−β(yk−fprev,k)`;

`uk=clip(u_raw,k,−5,5)`;

`I(k+1)=Ik+Ts[Ki(rk−yk)+Kaw(uk−u_raw,k)]`;

`fprev,(k+1)=α fprev,k+(1−α)yk`.

Source Kaw=20 s⁻¹; native tracking mode is enabled with this coefficient, internal output limiting disabled, external saturation returned to the tracking port. These settings indicate intended equivalence; actual native/explicit equality and scheduling still require later execution. No execution of that controller is inferred from Phase 2.

For unsaturated operation use state X=[i,y,I,fprev], c=[0,1], and U=[0,−Kp−β,1,β]. The transition matrix is

`F(top 2 rows)=[Ad,0,0]+Bd U`,

`F(row3)=[0,−Ts Ki,1,0]`, `F(row4)=[0,1−α,0,α]`.

Reference forcing is `Bcl=[Bd Kp; Ts Ki; 0]`. This is the source convention; replacing its roots with exp(continuous-poles Ts) would be wrong. It includes exact ZOH propagation of the continuous plant, not an Euler approximation of the plant.

| Case | Sampled roots | Spectral radius |
|---|---|---:|
| Historical | .4614605854±j.5307899872; .7887550111±j.1335661790 | .7999839946219522 |
| Rejected fast | .1569337311±j1.0116647047; .6684110014±j.2134957040 | **1.0237644606016603** |

These independently reproduce the stored stability results. The rejected oscillatory mode grows about2.376% per update in the unsaturated linear model. Clipping bounds voltage but does not turn an unstable linear equilibrium into a certified stable design.

New historical sampled response predictions, evaluated by exact state transitions and intersample exponentials over2 s: overshoot approximately**4.67597%**, settling approximately**0.17337 s**, input range about1.10593–1.91784 V. Thus the linear sampled candidate fails both performance targets although it is Schur stable. These estimates use intersample spacing Ts/101≈99.01 μs; they are not exact-certified continuous-time extrema or native measured timings. Their large margins establish analytical failure without relying on rounding near a threshold. The unsaturated nominal sequence stays within rails at every computed control update. No saturated nominal response is being passed off as a linear one.

### Filter sensitivity and noise

Historical N Ts=2.44; filter time constant1/N=.00409836 s is shorter than one update. Backward Euler filter pole α=.2906976744 differs substantially from exp(−2.44)≈.08716. The full-loop consequences, not just standalone filter stability, matter. Continuous derivative high-frequency gain is Kd N≈6.04720 V/V, while total proportional-plus-derivative measurement gain approaches7.26812 V/V. DOM avoids reference kick but still differentiates measurement noise. For the discrete filter, Nyquist derivative magnitude is `2 Kd N/(2+N Ts)`≈2.72396 V/V. No noise spectrum or hardware delay evidence is available to certify noise performance.

Holding the three historical gains fixed and changing only N illustrates sensitivity (analytical experiment only):

| N, s⁻¹ | Continuous roots, s⁻¹ | Continuous OS / settling | Sampled radius |
|---|---|---|---:|
|122|−58.9844±j75.2479; −27.0156±j11.7524|1.26759% / .0845976 s|.8134571|
|244|−38,−48,−58,−150|1.61757% / .0737619 s|.7999840|
|488|−426.6415; −41.2577±j29.6125; −28.8432|2.27306% / .1117118 s|.7914339|

Changing N alone destroys the matched poles; increasing filter bandwidth is not a monotonic cure for settling. A continuous ideal derivative has unbounded high-frequency gain and is not an implementation substitute.

### Saturation and anti-windup

For no initial clipping with DOM and zero states, Kp·1.53≤5 requires Kp≤3.2679738562, a necessary initial-demand condition only. The historical set satisfies it; the rejected fast set does not. Continuous derivative on error with the historical gains would instead initially request `(Kp+KdN)1.53≈11.12 V`, so changing derivative convention has a material saturation consequence.

In the unsaturated region the back-calculation correction is identically zero and cannot repair the historical nominal linear settling failure. During saturation, the integral is altered and neither the continuous polynomial nor F describes the entire response. Kaw=20 gives nominal tracking time constant.05 s and Ts Kaw=.2; this scalar fact is not a proof of global anti-windup stability or recovery. A load, infeasible reference, or controller noise can activate saturation even if a nominal step does not. Later native tests must establish raw/applied effort, integral-state behavior where observable, recovery, and explicit/native agreement. No such tests were run here.

## F. Design conclusion and unresolved mathematical task

**No replacement gains are selected for implementation.** Existing evidence supports exact analysis of the historical design, but not a design meeting the combined continuous and sampled transient requirements under the prescribed convention and rails.

As a diagnostic—not a recommended controller—the same exact quartic method was applied to somewhat faster real poles [−50,−60,−70,−180]. It gives Kp=2.313460978147763, Ki=62.18709677419355, Kd=.03471786781242658, N=310; Q=[.00051,.1836,21.981,1089.36,19278]. The roots match, and sampled radius≈.78089155 is stable. Nevertheless continuous OS≈7.95285%, settling≈.11986587 s; sampled OS≈12.21303%, settling≈.12505 s. Nominal analytical efforts stay within rails (continuous sampled extrema1.21936–3.59514 V; digital.29184–3.53960 V). Faster real poles have worsened tracking because the numerator and residues changed. This diagnostic is rejected, not promoted to an alternative baseline. All-real roots describe nonoscillatory modes; they do not justify assigning a second-order damping ratio to the entire fourth-order tracking response. Its filter and nonlinear caveats are the same as above.

The mathematically defensible alternative **design method** is constrained synthesis directly using the source's mixed-Euler sampled state matrix and DOM reference numerator, with simultaneous continuous checks. Variables are Kp,Ki,Kd,N (positive N), with explicit constraints: Hurwitz Q, Schur F with a declared robustness margin, peak output<1.5606 V, permanent band entry before.05 s, near-zero steady error, and bounded applied effort plus valid anti-windup dynamics if saturation is used. Check continuous intersample extrema and tails, not only five sample values. Avoid forcing arbitrarily selected real poles while ignoring numerator shape. Keep Ts=.01 and the prescribed rails. If no feasible point is found, distinguish failed search from a proof of architectural infeasibility; any architectural change would need its own authorization.

The precise unresolved mathematical question is **existence and identification of a four-parameter DOM filtered PID satisfying these simultaneous constraints under Forward Euler I, Backward Euler D, exact ZOH plant and the specified saturation/AW law**. Neither the three rejected/failed designs nor the feedforward reachability witness answers that question. No numerical gain set is invented to claim that it does. The current evidence does not justify advancing to native controller construction.

## G. Requirements-to-evidence matrix

| Requirement | Evidence class and finding | Current disposition |
|---|---|---|
| Nominal physical/TF plant agreement | NATIVE: previously audited Case A29/29, B30/30; six fresh comparisons per case; DERIVED: physical elimination and poles | Phase 2 CLOSED, unchanged |
| Visual Scope/model coverage | Earlier reviewed screenshots, closure record | Complete with readability/session limits; no cursor readings invented |
| Ideal and filtered equations | SOURCE master§10; DERIVED expansion, units, roots | Correct negative-feedback equations established; task's literal minus signs corrected explicitly |
| Historical intended poles/gains | SOURCE init parameters; DERIVED quartic and roots | Match; no coefficient defect |
| Historical continuous OS<2% | HISTORICAL1.617574799%; independently reproduced | Analytical PASS only, preserved |
| Historical settling<.05 s | HISTORICAL.07376186885457478 s; independently reproduced | **FAIL preserved** |
| Rise-time definition | Reference10–90%; historical.0475253374 s reproduced | Consistent; no additional acceptance threshold invented |
| Sampled linear stability, Ts=.01 | DERIVED exact source-convention F | Historical stable; fast candidate unstable, rejection preserved |
| Sampled tracking performance | DERIVED intersample prediction4.676% / .17337 s | Historical candidate analytically fails; no native claim |
| Actuator rails / AW recovery | Source±5 V,Kaw20; linear demand checks | Nominal historical demand plausible; nonlinear recovery unverified |
| Filter/noise/implementation equivalence | Source DOM, FE/BE; DERIVED sensitivity | Mathematical convention identified; native equivalence/noise robustness unverified |
| Steady-state tracking | DERIVED stable unsaturated DC gain1 | Zero nominal error predicted; loads constrained by rails |
| Feasibility of deadline | DERIVED bounded3-interval reachability witness | Plant/sample/rail impossibility not established; PID feasibility unresolved |
| Revised acceptable PID | No qualifying gains selected | **OPEN: constrained analytical synthesis** |
| Model provenance | Closure record, preserved two hashes | Unresolved; no original-model continuity claim |
| Overall project | Open-loop closure only; controller validation absent | **NOT ACCEPTED** |

## H. Reproducibility and preservation

The appended calculation source is new independent analysis; it neither imports nor runs the candidate's analytical_audit.py, builder or verification script. Continuous response metrics are evaluated from rational residues, with scalar root finding for threshold crossings and bounded peak refinement. Control extrema are dense analytical evaluations, not certified global bounds. Sampled responses use exact matrix exponentials on each held-input interval, evaluated on a finite grid; numerical precision and finite horizon are disclosed above. The rejected unstable sequence's large unbounded predictions are not physical rail-limited outputs. No finite-horizon calculation constitutes nonlinear or robust certification.

All prior reports, matrices, sources, manifests, model and archives remain untouched. New source hashes and continuity record hashes appear below for traceability. The original candidate ZIP was recovered as a separate read copy; no candidate release was rebuilt. No model was opened, modified, saved or simulated. No PID was implemented.

## I. Exactly one next-step recommendation

**Continue Phase 3 with a constrained analytical sampled-PID synthesis review under the existing DOM/Forward-Euler-I/Backward-Euler-D convention, Ts=.01 s, ±5 V rails and unchanged acceptance criteria; return either a fully assessed candidate or an explicitly bounded infeasibility finding before authorizing any native controller implementation.**

Stop here. This review is not project acceptance and authorizes no model changes or simulation.


## Appendix 1. Source identities

Candidate archive SHA-256: `6826c36c37bf9bd2517e21f6f53762d67e23f0a29e0e2b9f0b50435c7954c078`.

| Original archive member | SHA-256 |
|---|---|
| LRC_Control_Candidate/ENGINEERING_REPORT.md | `f244eafc54857bef257a8d9cb6ba67b28be3e48bb120fd26c6dc43e222f4a69e` |
| LRC_Control_Candidate/analytical_audit.py | `a88cca1206994c3673656203428bcabd514d2541c7350ab29f3fa7e8b0cbe4da` |
| LRC_Control_Candidate/evidence/analytical_results.json | `f8c4c0015bd41b222b910cd376c40d6fdfcb0b979a9caf71e45d75b0044afdbb` |
| LRC_Control_Candidate/init_lrc_pid.m | `9bba69abdeb825285e4565d42fccb80b1487dfe5b923a50135ddd8a281e13aa3` |
| LRC_Control_Candidate/run_lrc_verification.m | `c56fcef1a2f4512170c79d56e401b26e5b6a5ce7d152610400ac5633df286fc5` |
| LRC_Control_Candidate/sources/MASTER_EXECUTION_PROMPT.txt | `c9a36231db3f0e50b1c1d4d29a394f3b431a501c29011d60fc19a246fbebb759` |

Continuity record `PHASE2_FORMAL_CLOSURE_RECORD_20261024.md` SHA-256: `48d9b477f0c64252e68829cd9bdd54393f7da24531a54e4bce46c640c1adcb2f`.

Continuity record `PHASE2_TRACE_AVAILABILITY_AND_REQUIREMENT_CORRECTION.md` SHA-256: `83fe10d8a55cb0e3f465f9c79fadddb327d0069f7b08b62674cadc8f5997fc1e`.

Continuity record `PHASE2_RECONCILED_STATUS_ADDENDUM.md` SHA-256: `dbe72cb9f465cc143b945fd2b8736c3414290c249915af547ee3665a1ddc59e6`.

Continuity record `PHASE2_RECONCILED_STATUS_ADDENDUM_SCOPE_REVIEW.md` SHA-256: `7d7d91d98546bed279340636d6869efee35bcf3bdf036f02536e4b521631c6c1`.

## Appendix 2. Independent calculation source

```python
import numpy as np, json, zipfile, hashlib
from scipy.linalg import expm
from scipy.signal import residue
from scipy.optimize import brentq, minimize_scalar
from pathlib import Path
a,b,E,T=.00051,.0255,1.53,.01
Ap=np.array([[-50.,-1.],[1/a,0.]])
M=np.zeros((3,3));M[:2,:2]=Ap;M[0,2]=1
Z=expm(M*T);Ad=Z[:2,:2];Bd=Z[:2,2]
def design(p):
 q=a*np.poly(p);N=q[1]/a-50;ki=q[4]/N;kp=(q[3]-ki)/N-1;kd=(q[2]-1-b*N-kp)/N
 return kp,ki,kd,N
def assess(g):
 kp,ki,kd,N=g
 den=[a,b+a*N,1+b*N+kp+kd*N,N*(1+kp)+ki,ki*N]
 num=np.convolve([kp,ki],[1,N])
 rr,pp,_=residue(E*num,np.convolve(den,[1,0]))
 def y(t):return np.real(np.exp(np.asarray(t)[...,None]*pp)@rr)
 tt=np.linspace(0,2,20001);yy=y(tt);bad=np.where(abs(yy-E)>.02*E)[0];j=bad[-1]
 ts=brentq(lambda t:abs(y(t)-E)-.02*E,tt[j],tt[j+1]) if j<len(tt)-1 else None
 crosses=[]
 for f in [.1,.9]:
  j=np.where(yy>=f*E)[0][0];crosses.append(brentq(lambda t:y(t)-f*E,tt[j-1],tt[j]))
 j=np.argmax(yy);pk=minimize_scalar(lambda t:-y(t),bounds=(tt[max(0,j-1)],tt[min(len(tt)-1,j+1)]),method='bounded')
 ur,up,_=residue(E*np.convolve([a,b,1],num),np.convolve(den,[1,0]));uu=np.real(np.exp(tt[:,None]*up)@ur)
 alpha=1/(1+N*T);beta=kd*N*alpha;u=np.array([0,-kp-beta,1,beta]);F=np.zeros((4,4));F[:2,:2]=Ad;F[:2]+=Bd[:,None]*u;F[2]=[0,-T*ki,1,0];F[3]=[0,1-alpha,0,alpha]
 B=np.r_[Bd*kp,T*ki,0];eig=np.linalg.eigvals(F)
 x=np.zeros(4);sd=[];us=[]
 # Exact ZOH plant propagation between samples; no numerical ODE solver.
 tau=np.linspace(0,T,101,endpoint=False);ZZ=np.array([expm(M*t) for t in tau])
 for k in range(200):
  uk=u@x+kp*E;us.append(uk)
  vals=np.einsum('tij,j->ti',ZZ[:,:2,:2],x[:2])+ZZ[:,:2,2]*uk
  sd.extend(zip(k*T+tau,vals[:,1]));x=F@x+B*E
 sd=np.array(sd);bad=np.where(abs(sd[:,1]-E)>.02*E)[0]
 return dict(gains=list(g),coefficients=den,roots=[[v.real,v.imag] for v in np.roots(den)],ideal_roots=[[v.real,v.imag] for v in np.roots([a,b+kd,1+kp,ki])],continuous=dict(settling=ts,overshoot=100*(-pk.fun-E)/E,rise=crosses[1]-crosses[0],y_at_005=float(y(.05)),u_min=float(min(uu)),u_max=float(max(uu))),discrete=dict(poles=[[v.real,v.imag] for v in eig],rho=float(max(abs(eig))),settling_grid=None if bad[-1]==len(sd)-1 else float(sd[bad[-1]+1,0]),overshoot_grid=float(100*(max(sd[:,1])-E)/E),u_min=float(min(us)),u_max=float(max(us))),step_residues=[[v.real,v.imag] for v in rr],step_poles=[[v.real,v.imag] for v in pp])
if __name__=='__main__':
 zpath=Path('phase3_sources/LRC_Control_Construction_CANDIDATE.zip')
 with zipfile.ZipFile(zpath) as z:
  old=json.loads(z.read('LRC_Control_Candidate/evidence/analytical_results.json'))
 results={}
 for name,p in [('historical',[-38,-48,-58,-150]),('rejected',[-80,-90,-100,-300]),('alternative',[-50,-60,-70,-180])]:results[name]=assess(design(p))
 results['filter_sensitivity']={str(N):assess((*results['historical']['gains'][:3],N)) for N in [122,488]}
 Path('phase3_analysis/calculations.json').write_text(json.dumps(results,indent=2))
 print(json.dumps(results,indent=2))

```

## Appendix 3. Unrounded independent calculation outputs

```json
{
  "historical": {
    "gains": [
      1.2209160924482672,
      33.16839344262296,
      0.02478362257193334,
      244.0
    ],
    "coefficients": [
      0.00051,
      0.14994000000000002,
      14.490120000000001,
      575.0719200000001,
      8093.088000000002
    ],
    "roots": [
      [
        -150.00000000000006,
        0.0
      ],
      [
        -57.99999999999988,
        0.0
      ],
      [
        -47.9999999999997,
        0.0
      ],
      [
        -38.000000000000234,
        0.0
      ]
    ],
    "ideal_roots": [
      [
        -35.940323229324946,
        33.80475228954495
      ],
      [
        -35.940323229324946,
        -33.80475228954495
      ],
      [
        -26.714691917689944,
        0.0
      ]
    ],
    "continuous": {
      "settling": 0.07376186885457482,
      "overshoot": 1.617574799079941,
      "rise": 0.04752533741350102,
      "y_at_005": 1.2779400989999454,
      "u_min": 1.2463853602370625,
      "u_max": 1.92545782736793
    },
    "discrete": {
      "poles": [
        [
          0.4614605854073983,
          0.5307899871687616
        ],
        [
          0.4614605854073983,
          -0.5307899871687616
        ],
        [
          0.7887550110592976,
          0.13356617902801304
        ],
        [
          0.7887550110592976,
          -0.13356617902801304
        ]
      ],
      "rho": 0.7999839946219522,
      "settling_grid": 0.17336633663366338,
      "overshoot_grid": 4.675965640235483,
      "u_min": 1.105928396524292,
      "u_max": 1.9178364333665714
    },
    "step_residues": [
      [
        1.530000000000003,
        0.0
      ],
      [
        9.602827029505209,
        0.0
      ],
      [
        -30.547631636025166,
        0.0
      ],
      [
        19.68306303880439,
        0.0
      ],
      [
        -0.26825843228432034,
        0.0
      ]
    ],
    "step_poles": [
      [
        0.0,
        0.0
      ],
      [
        -38.000000000000234,
        0.0
      ],
      [
        -47.9999999999997,
        0.0
      ],
      [
        -57.99999999999988,
        0.0
      ],
      [
        -150.00000000000006,
        0.0
      ]
    ]
  },
  "rejected": {
    "gains": [
      6.41914201183432,
      211.84615384615387,
      0.06340934228493401,
      520.0
    ],
    "coefficients": [
      0.00051,
      0.2907,
      53.652,
      4069.8,
      110160.00000000001
    ],
    "roots": [
      [
        -300.00000000000057,
        0.0
      ],
      [
        -99.99999999999733,
        0.0
      ],
      [
        -90.00000000000412,
        0.0
      ],
      [
        -79.99999999999841,
        0.0
      ]
    ],
    "ideal_roots": [
      [
        -62.29070515688208,
        66.85208492193249
      ],
      [
        -62.29070515688208,
        -66.85208492193249
      ],
      [
        -49.750633382184795,
        0.0
      ]
    ],
    "continuous": {
      "settling": 0.0870228532898131,
      "overshoot": 17.866816204167833,
      "rise": 0.014955472790537562,
      "y_at_005": 1.7406855332789555,
      "u_min": 0.29310394171988713,
      "u_max": 9.895291258301416
    },
    "discrete": {
      "poles": [
        [
          0.1569337311145343,
          1.01166470474633
        ],
        [
          0.1569337311145343,
          -1.01166470474633
        ],
        [
          0.6684110014480177,
          0.21349570401971044
        ],
        [
          0.6684110014480177,
          -0.21349570401971044
        ]
      ],
      "rho": 1.0237644606016603,
      "settling_grid": null,
      "overshoot_grid": 5438.330839213097,
      "u_min": -817.4014037636825,
      "u_max": 828.3146240714626
    },
    "step_residues": [
      [
        1.5299999999999985,
        0.0
      ],
      [
        113.13195266266202,
        0.0
      ],
      [
        -249.72531699073357,
        0.0
      ],
      [
        135.47143491134105,
        0.0
      ],
      [
        -0.4080705832628864,
        0.0
      ]
    ],
    "step_poles": [
      [
        0.0,
        0.0
      ],
      [
        -79.99999999999841,
        0.0
      ],
      [
        -90.00000000000412,
        0.0
      ],
      [
        -99.99999999999733,
        0.0
      ],
      [
        -300.00000000000057,
        0.0
      ]
    ]
  },
  "alternative": {
    "gains": [
      2.313460978147763,
      62.18709677419355,
      0.03471786781242658,
      310.0
    ],
    "coefficients": [
      0.00051,
      0.1836,
      21.981,
      1089.3600000000001,
      19278.0
    ],
    "roots": [
      [
        -180.00000000000006,
        0.0
      ],
      [
        -70.00000000000237,
        0.0
      ],
      [
        -59.999999999996156,
        0.0
      ],
      [
        -50.0000000000015,
        0.0
      ]
    ],
    "ideal_roots": [
      [
        -42.49118942046287,
        43.35037656436381
      ],
      [
        -42.49118942046287,
        -43.35037656436381
      ],
      [
        -33.09187177167542,
        0.0
      ]
    ],
    "continuous": {
      "settling": 0.11986586911000106,
      "overshoot": 7.952847881442314,
      "rise": 0.028686908401486588,
      "y_at_005": 1.5988910207749296,
      "u_min": 1.219356811347919,
      "u_max": 3.5951402141141173
    },
    "discrete": {
      "poles": [
        [
          0.39523409681067295,
          0.6734846830818445
        ],
        [
          0.39523409681067295,
          -0.6734846830818445
        ],
        [
          0.7509994639452786,
          0.15848716786136516
        ],
        [
          0.7509994639452786,
          -0.15848716786136516
        ]
      ],
      "rho": 0.780891547929417,
      "settling_grid": 0.12504950495049505,
      "overshoot_grid": 12.213032630125953,
      "u_min": 0.2918430993522314,
      "u_max": 3.5395952965660773
    },
    "step_residues": [
      [
        1.5299999999999996,
        0.0
      ],
      [
        32.09157127993366,
        0.0
      ],
      [
        -79.81308532777062,
        0.0
      ],
      [
        46.6387815721966,
        0.0
      ],
      [
        -0.44726752435909556,
        0.0
      ]
    ],
    "step_poles": [
      [
        0.0,
        0.0
      ],
      [
        -50.0000000000015,
        0.0
      ],
      [
        -59.999999999996156,
        0.0
      ],
      [
        -70.00000000000237,
        0.0
      ],
      [
        -180.00000000000006,
        0.0
      ]
    ]
  },
  "filter_sensitivity": {
    "122": {
      "gains": [
        1.2209160924482672,
        33.16839344262296,
        0.02478362257193334,
        122
      ],
      "coefficients": [
        0.00051,
        0.08772,
        8.355518046224134,
        304.12015672131156,
        4046.544000000001
      ],
      "roots": [
        [
          -58.984383228771094,
          75.24792839872151
        ],
        [
          -58.984383228771094,
          -75.24792839872151
        ],
        [
          -27.015616771229006,
          11.752404187903226
        ],
        [
          -27.015616771229006,
          -11.752404187903226
        ]
      ],
      "ideal_roots": [
        [
          -35.940323229324946,
          33.80475228954495
        ],
        [
          -35.940323229324946,
          -33.80475228954495
        ],
        [
          -26.714691917689944,
          0.0
        ]
      ],
      "continuous": {
        "settling": 0.084597620522203,
        "overshoot": 1.2675878988646982,
        "rise": 0.048789565123729096,
        "y_at_005": 1.2878073092874944,
        "u_min": 1.1521782218821692,
        "u_max": 1.962930349664692
      },
      "discrete": {
        "poles": [
          [
            0.5424748021159527,
            0.5512679900261288
          ],
          [
            0.5424748021159527,
            -0.5512679900261288
          ],
          [
            0.8038983888527891,
            0.12433768533892568
          ],
          [
            0.8038983888527891,
            -0.12433768533892568
          ]
        ],
        "rho": 0.8134571160150681,
        "settling_grid": 0.1718811881188119,
        "overshoot_grid": 4.901583174737697,
        "u_min": 1.0345859041900707,
        "u_max": 1.9786630735969175
      },
      "step_residues": [
        [
          1.5299999999999971,
          0.0
        ],
        [
          -0.8294904583467076,
          0.3568609492652866
        ],
        [
          -0.8294904583467076,
          -0.3568609492652866
        ],
        [
          0.06449045834670906,
          -0.30298828191257154
        ],
        [
          0.06449045834670906,
          0.30298828191257154
        ]
      ],
      "step_poles": [
        [
          0.0,
          0.0
        ],
        [
          -27.015616771229006,
          -11.752404187903226
        ],
        [
          -27.015616771229006,
          11.752404187903226
        ],
        [
          -58.984383228771094,
          -75.24792839872151
        ],
        [
          -58.984383228771094,
          75.24792839872151
        ]
      ]
    },
    "488": {
      "gains": [
        1.2209160924482672,
        33.16839344262296,
        0.02478362257193334,
        488
      ],
      "coefficients": [
        0.00051,
        0.27438,
        26.759323907551735,
        1116.9754465573774,
        16186.176000000003
      ],
      "roots": [
        [
          -426.6414893324271,
          0.0
        ],
        [
          -41.25765308717685,
          29.61253002874289
        ],
        [
          -41.25765308717685,
          -29.61253002874289
        ],
        [
          -28.843204493219613,
          0.0
        ]
      ],
      "ideal_roots": [
        [
          -35.940323229324946,
          33.80475228954495
        ],
        [
          -35.940323229324946,
          -33.80475228954495
        ],
        [
          -26.714691917689944,
          0.0
        ]
      ],
      "continuous": {
        "settling": 0.11171179196720304,
        "overshoot": 2.273058301862931,
        "rise": 0.04666991902919869,
        "y_at_005": 1.2778620984616753,
        "u_min": 1.2978041013822548,
        "u_max": 1.900205375525631
      },
      "discrete": {
        "poles": [
          [
            0.3985151263307208,
            0.5010947180283518
          ],
          [
            0.3985151263307208,
            -0.5010947180283518
          ],
          [
            0.7790916742874918,
            0.13922546890691273
          ],
          [
            0.7790916742874918,
            -0.13922546890691273
          ]
        ],
        "rho": 0.791433868454236,
        "settling_grid": 0.16960396039603962,
        "overshoot_grid": 4.855357105221319,
        "u_min": 1.155365129297341,
        "u_max": 1.8719061131926364
      },
      "step_residues": [
        [
          1.5299999999999991,
          0.0
        ],
        [
          0.23832579505531185,
          -0.0
        ],
        [
          -0.8823924970327683,
          -1.1388331216222114
        ],
        [
          -0.8823924970327683,
          1.1388331216222114
        ],
        [
          -0.003540800989775764,
          -1.1992708507005929e-20
        ]
      ],
      "step_poles": [
        [
          0.0,
          0.0
        ],
        [
          -28.843204493219613,
          0.0
        ],
        [
          -41.25765308717685,
          -29.61253002874289
        ],
        [
          -41.25765308717685,
          29.61253002874289
        ],
        [
          -426.6414893324271,
          0.0
        ]
      ]
    }
  }
}
```

## Appendix 4. Reachability witness interval extrema

```json
[
  {
    "input": 5.0,
    "voltage_extrema": [
      [
        0,
        [
          0.0,
          0.0
        ]
      ],
      [
        0.01,
        [
          0.03807888600462856,
          0.41121920012637864
        ]
      ]
    ],
    "end": [
      0.03807888600462856,
      0.41121920012637864
    ]
  },
  {
    "input": 2.8049560614332454,
    "voltage_extrema": [
      [
        0,
        [
          0.03807888600462856,
          0.41121920012637864
        ]
      ],
      [
        0.01,
        [
          0.03867728321554452,
          1.1767173741018737
        ]
      ]
    ],
    "end": [
      0.03867728321554452,
      1.1767173741018737
    ]
  },
  {
    "input": -1.5503104510154384,
    "voltage_extrema": [
      [
        0,
        [
          0.03867728321554452,
          1.1767173741018737
        ]
      ],
      [
        0.009999999999999998,
        [
          5.204170427930421e-18,
          1.5300000000000002
        ]
      ],
      [
        0.01,
        [
          0.0,
          1.5300000000000002
        ]
      ]
    ],
    "end": [
      0.0,
      1.5300000000000002
    ]
  }
]
```
