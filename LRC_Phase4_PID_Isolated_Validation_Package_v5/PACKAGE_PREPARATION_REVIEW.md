# V5 package-preparation review — 2026-10-26

READY FOR OWNER REVIEW. Overall NOT ACCEPTED.

Final manifest: 88 components. Final ZIP: 89 entries including the manifest. Exact archive integrity, clean extraction, manifest completeness and all component hashes are verified after release freeze; the included verifier log reproduces the completed-archive output. V1–V4 hashes remain unchanged.

The owner reported an actual R2026a/Simulink26.1 Stage A failure because LimitIntegratorOutput was absent. Local read-only inspection identified LimitIntegrator, UpperIntegratorSaturationLimit=inf and LowerIntegratorSaturationLimit=-inf, separate from LimitOutput. This is user-reported native evidence, not a session accessed by this preparer.

The sole changed MATLAB file is phase4_build.m. The original required-field assertion is retained; it now requires LimitIntegrator and the two associated limit fields. LimitIntegrator and LimitOutput are independently set/checked off. Infinite upper/lower integrator defaults are checked before configuration and numerically checked afterward without rewriting them; equivalent inf/Inf spelling is harmless. The current architecture statement is corrected. Historical failed-name references are retained and classified in V5_PARAMETER_NAME_SEARCH.json.

Static results: 27 parameter/architecture checks PASS; 26 individual missing-required-field fixtures reject as intended. The original22 authorization predicates and7 ordering checks PASS unchanged. The new harness rejects the unmodified V4 builder in a temporary regression fixture. All13 MATLAB source files parse with MISS_HIT0.9.44; Python sources parse. These are source-derived/static checks, not MATLAB runtime validation.

All baseline files, fixed candidate/plant/constants, controller equations, four-path architecture, sample time, Kaw, solver settings, acceptance criteria, overshoot formulas, owner template and Stage A/B gates remain unchanged. The failed local Stage A directory and owner record were not accessed or altered; preserve them and use a new directory/new V5-bound Stage A record only after separate authorization.

No MATLAB/Simulink execution, construction, compilation, simulation or model modification occurred here. Native construction success and equivalence remain UNVERIFIED. Phase3 Decision2 remains unchanged, the Phase2 model-hash discrepancy remains unresolved, and no robustness/deployment/project acceptance is claimed. The addendum, exact source diff, before/after hashes, static logs and preservation record accompany the package.
