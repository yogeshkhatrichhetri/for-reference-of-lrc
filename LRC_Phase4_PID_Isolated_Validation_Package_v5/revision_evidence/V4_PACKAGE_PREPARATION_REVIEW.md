# V4 package-preparation review — 2026-10-25

READY FOR OWNER REVIEW. Overall NOT ACCEPTED.

The final manifest contains 72 components; the ZIP contains 73 file entries including the manifest. Manifest completeness and all hashes are checked after clean extraction of the actual completed archive. The included final verifier output matches that completed-release execution exactly. Current static evidence and inventory record the same count. V1/V2/V3 outer hashes remain unchanged.

The only MATLAB change is relocation of the unchanged supplemental approval assertion into an early stress-only conditional immediately after scenario/precision validation. It precedes mkdir, isolation, load_system, diary, stress configuration and sim. Reversing the relocation reproduces the V3 runner exactly. Nominal behavior and all Stage B/identity/criteria requirements remain unchanged. All other MATLAB source files, baseline files, test criteria, authorization template, overshoot formulas, gains, controller equations, plant and solver settings are byte-identical to V3.

All22 original Boolean predicate tests are retained unchanged and pass. Seven new ordering checks pass. A separate static regression fixture using the original V3 late placement is rejected at guard_before_run_directory_creation, as intended. All13 MATLAB source files pass MISS_HIT0.9.44 syntax parsing. Python tooling syntax passes. These are static/source-derived results, not native MATLAB guard tests or observed runtime filesystem behavior.

See revision_evidence/AUTHORIZATION_STATIC_TESTS.json, V4_ORDERING_REGRESSION.json, MATLAB_SYNTAX_LOG.txt, V4_PRESERVATION.json, V4_SOURCE_DIFF.patch and V4_CHANGED_SOURCE_HASHES.csv. Prior records are retained under their historical names or V3_* copies. No historical model identity, original manifest or Phase3 robustness Decision2 is changed. The Phase2 model-hash discrepancy remains unresolved.

No MATLAB/Simulink execution, native construction, compilation or simulation occurred. Native equivalence, robustness, deployment readiness and project acceptance remain unclaimed. Stop at package review.
