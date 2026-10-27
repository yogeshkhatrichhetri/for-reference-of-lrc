# V3 narrowly scoped corrective revision — 2026-10-25

V2 SHA-256:e8454d5db7ca041fbb38f21226d75cdf15ea58a8dce34099d3563dd02b8103be. V2 ZIP integrity and all49 component checksums PASS; V1 and V2 remain unchanged.

Only one MATLAB statement changes: the stress-only approval assertion in phase4_run.m. It now requires field existence, islogical, isscalar and isequal(value,true), using short-circuit &&. A missing/malformed value stops before stress-specific configuration and sim. The assertion remains inside the stress conditional; nominal scenarios are not made contingent on supplemental approval. Stage A and Stage B code and identity requirements are unchanged.

The previous assertion expressed truthiness without the declared type/scalar policy. The correction enforces that policy rather than changing test criteria. The source-derived Python harness recognizes the exact new predicate, verifies its location before stress configuration/execution, and covers missing, false, true, string, numeric1, logical array, empty array, null and object values. A separate nominal case verifies valid Stage B Boolean predicates with stress approval false. All identity checks remain independently required; a positive Boolean predicate is not execution authorization by itself.

The original12 Stage A/B tests are retained, giving22 static predicate cases total. This is not MATLAB runtime guard execution or numerical plant/controller validation. README agrees with the unchanged default-false authorization template. All other MATLAB sources, baseline files, source model, manifests in baseline/, test register, gains, controller equations, solver settings and overshoot formulas remain byte-identical to V2. Existing V1/V2 evidence is retained. The model-hash discrepancy and historical Phase3 Decision2 remain unresolved/unchanged respectively. Overall NOT ACCEPTED.

Final logs are captured, frozen, manifested and reproduced against the actual completed ZIP after clean extraction. No native construction, compilation, simulation, equivalence or robustness claim is made.
