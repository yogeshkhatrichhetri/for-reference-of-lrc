# Proposed experiment architecture and equations

Status: SOURCE-BASED DESIGN, NOT NATIVE EXECUTION EVIDENCE.

Four independent branches: CE explicit continuous, CN native continuous, DE explicit discrete, DN native discrete. Each drives a separate copy of the audited Physical_LRC subsystem through its own external Saturation block. No cross-branch feedback. Reference 1.53 V from t=0, all states zero, load current zero, baseline duration 1 s. Plant i'=(u-50i-y)/L, y'=i/C. Reference and measured y are sampled at Ts for DE/DN; applied discrete controls are held. No inserted computational delay, quantizer, measurement noise, or uncertainty screen.

Frozen constants are exact decimal literals in matlab/p4_constants.m; no tuning interfaces are provided.

## Explicit equations

Continuous: e=r-y, f'=N(y-f), D=-Kd*N*(y-f), raw=Kp*e+I+D,
u=clip(raw,-5,5), aw=Kaw*(u-raw), I'=Ki*e+aw.

Discrete: alpha=1/(1+N*Ts), beta=Kd*N*alpha;
e[k]=r[k]-y[k], D[k]=-beta*(y[k]-fprev[k]), raw[k]=Kp*e[k]+I[k]+D[k];
u[k]=clip(raw[k],-5,5), aw[k]=Kaw*(u[k]-raw[k]);
I[k+1]=I[k]+Ts*(Ki*e[k]+aw[k]);
fprev[k+1]=alpha*fprev[k]+(1-alpha)*y[k].

I[k] and fprev[k] are pre-update states. Current output uses current y, old I, and old fprev. Unit Delay blocks make the explicit update timing visible. No one-sample delay is added to applied control.

## Native configuration and supported external anti-windup

Use simulink/Continuous/PID Controller (2DOF) in both time domains. Required settings: PID, Parallel, internal parameters, P=Kp, I=Ki, D=Kd, N=N, b=1, c=0, zero internal initial conditions, no external reset. Continuous TimeDomain for CN; Discrete-time for DN with SampleTime=Ts, IntegratorMethod=Forward Euler, FilterMethod=Backward Euler, UseFilter=on. UseKiTs=off, UseExternalTs=off, LimitIntegratorOutput=off.

The external Saturation feeds both the plant and native TR input. TrackingMode=on, Kt=Kaw; LimitOutput=off avoids double limiting. The documented tracking difference enters the integrator input. With UseKiTs off, the native discrete integrator supplies Ts; do not pre-scale Ki or Kt. These settings are consistent with the reference law, but local scheduling and trajectories remain unverified. Missing parameters, unexpected ports, compilation errors or failed recurrence residuals stop the branch; never alter the reference law to make it match.

R2026a official reference, accessed 2026-10-25:
https://www.mathworks.com/help/releases/R2026a/simulink/slref/pidcontroller2dof.html
Relevant headings: Form; Integrator method; Filter method; Use I*Ts; Enable tracking mode; Tracking coefficient; Limit Output. The native continuous and discrete blocks are documented as the same block with different TimeDomain settings. This review uses the release-specific page, not a claim of access to the owner's installation.

## Observability and interpretation

Every branch logs y, i, raw, applied, aw, I, f, D, error, ref, plus complete Simulink state output. CE/DE I and f are explicit states. CN/DN f is an independent filter observer driven only by that branch's measurement; native I is reconstructed as raw-Kp*e-D_observer. Those are NOT direct native internal-state measurements. Their recurrence residuals, exact native parameter snapshot, output/control equivalence and saturation recovery jointly test the convention. The package never labels a reconstructed state as directly measured.

Each Scope shows y, i, raw, applied, aw with named traces. Manual observation is supplemental to numerical logging. Preserve screenshots with filenames identifying branch/scenario/precision and notes identifying any cursor values actually observed. Do not invent cursor evidence.

## Polynomial, state transition and tail checks

For P(s)=a s^2+b s+1, the filtered characteristic polynomial is
[a, b+aN, 1+bN+Kp+KdN, N(1+Kp)+Ki, Ki*N].
Derivative-on-measurement changes the reference numerator, not this negative-feedback characteristic denominator. No ideal-PID pole matching is used.

p4_tail forms the unsaturated continuous state matrix for x=[i,y,I,f] from the above equations. For discrete x=[i,y,I,fprev], it uses exact expm of the augmented physical plant for Ad,Bd, followed by the prescribed FE/BE recurrence. It reports poles and stability (Re(lambda)<0 continuous, rho<1 discrete), and conditional future bounds from the terminal state relative to [0,r,r,r].

For stable F=V diag(lambda) V^-1, z=V^-1(x_end-x_eq), each discrete modal magnitude cannot grow with k; continuous magnitudes cannot grow with t. The continuous output and control bounds sum absolute modal coefficients. For the sampled intersample voltage, each mode is propagated as y(theta)=[0,1]exp(A theta)(vplant-[0,1]'q)+q, q=U*v. Bounding the stable plant modal exponentials by one gives a uniform bound for every theta in [0,Ts], not just endpoints. The applied control bound must stay inside rail headroom so the unsaturated continuation is self-consistent. A factor 10 plus 1e-9 guards numerical roundoff; this is NOT a formal interval-arithmetic proof. Ill-conditioned modal bases (condition number >=1e10) fail the tail check. Native bounds remain conditional on the declared/verified block convention and reconstructed states.

Stable equilibrium is y=r, i=0, f=r, I=r, raw=u=r=1.53 V, with zero tracking error and no AW correction. Finite-time error is reported separately. Neither linear roots alone nor a short smooth trace proves arbitrary nonlinear/global stability.

## File-generation isolation

p4_isolate redirects working directory, CacheFolder and CodeGenFolder into the current new build/run directory and restores the previous session configuration/path on return. No code generation is invoked. Supported API reference: https://www.mathworks.com/help/simulink/slref/simulink.filegencontrol.html (getConfig/set; accessed2026-10-25).
