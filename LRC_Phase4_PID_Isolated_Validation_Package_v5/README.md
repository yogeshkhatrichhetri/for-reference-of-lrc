# Isolated PID nominal implementation-validation package

Package preparation only. Do not execute MATLAB/Simulink until a separate instruction authorizes the local experiment. Research-only PID subtask; NOT full Phase4 completion. Overall NOT ACCEPTED. Phase3 robustness Decision2 is preserved.

Read BASELINE_IDENTITY.md, ARCHITECTURE_AND_SEMANTICS.md, TEST_REGISTER.md and LIMITATIONS_AND_UNEXECUTED.md first. baseline/ contains unchanged source/evidence copies; never run baseline/init_lrc_pid.m. Only matlab/ belongs on the MATLAB path.

## 1. Extract and verify without MATLAB

Keep the original ZIP unchanged. On Ubuntu, create an empty parent directory and extract into it:

```bash
work=$(mktemp -d "$HOME/LRC_P4_package_XXXXXXXX")
python3 -m zipfile -t /absolute/path/LRC_Phase4_PID_Isolated_Validation_Package_v5.zip
python3 -m zipfile -e /absolute/path/LRC_Phase4_PID_Isolated_Validation_Package_v5.zip "$work"
cd "$work/LRC_Phase4_PID_Isolated_Validation_Package_v5"
python3 tools/verify_package.py
```

Compare the ZIP SHA-256 with the delivery value before extraction (`sha256sum /absolute/path/...zip`). verify_package.py checks all component hashes, inventory coverage and source identity. It never calls MATLAB, opens a model, or writes project files.

## 2. Two independent, disabled-by-default approval stages

Current authorization is package preparation only. Do not execute the following native commands yet.

Stage A authorizes only construction/update/compilation, fingerprinting and saving the new isolated model. Copy OWNER_REVIEW_TEMPLATE.json OUTSIDE the package as OWNER_CONSTRUCTION.json. After explicit owner authorization, fill owner/UTC, set construction_authorized=true, and leave simulation_authorized=false. Proposed-criteria and stress approvals may remain false for Stage A. Populate package_manifest_sha256 using `sha256sum SHA256SUMS.txt`. Retain the supplied source_sha256 and unchanged test_register_sha256. Do not edit the frozen package. Stage A has no call to sim or the scenario runner.

After successful construction, close without saving any inspection changes. Preserve OWNER_CONSTRUCTION.json and build_record.json unchanged. Stage A does NOT authorize a simulation through the GUI, sim(), or any other route. The package guards enforce its supported script entry points; they cannot prevent an owner from deliberately bypassing scripts in MATLAB.

Stage B requires a NEW separate owner decision. Copy the default template outside the package as OWNER_SIMULATION.json; do not repurpose the Stage A approval record. Set simulation_authorized=true only after that decision. Set proposed_criteria_approved=true only after reviewing TEST_REGISTER.md. Set supplemental_stress_approved=true only if the labelled synthetic stress case is approved. construction_authorized may remain false in this separate Stage B record: completed construction is established by the preserved Stage A build record, not a renewed construction permission.

Bind Stage B to the same package_manifest_sha256, source_sha256 and test_register_sha256. Fill constructed_model_sha256 from the actual saved model and build_record_sha256 from the completed build_record.json, using sha256sum. Both must match the constructed file and recorded identities. No model/build hash is supplied or fabricated at package-preparation time.

A missing/false/malformed permission or missing/mismatched identity stops before any simulation. Owner fields must use JSON true/false, not strings or numbers. Each applicable approval record and its SHA-256 are recorded in build/run evidence. No Stage A code writes or enables Stage B. If proposed criteria are rejected, stop for a new versioned review; do not weaken thresholds in place.

## 3. Construction only, after separate authorization

MATLAB R2026a / Simulink26.1 and a valid Simulink license are required. No Control System Toolbox or tuning toolbox is used. Build and each run redirect working/cache/code-generation directories into their own new experiment-stage directory and restore the prior session paths afterward. No code generation is requested. Use a clean desktop session for Scope inspection, double precision, normal simulation mode, Java enabled. Have several GB free memory/disk for dense evidence. Commands below are instructions for later owner execution; they have NOT been run by the AI.

```matlab
pkg = '/absolute/path/LRC_Phase4_PID_Isolated_Validation_Package_v5';
addpath(fullfile(pkg,'matlab'));  % DO NOT use genpath(pkg)
owner = fullfile(fileparts(pkg),'OWNER_CONSTRUCTION.json');
out = fullfile(fileparts(pkg),'P4_RUN_20261025_001'); % new, nonexistent sibling
phase4_build(out,owner)
```

This copies only the audited physical subsystem into a new four-branch model, checks masks/ports, compiles, saves, fingerprints and hashes that NEW model. It does not simulate. The baseline source copy is closed without saving. If any construction/assertion error occurs, retain the folder/diary; do not repair or overwrite it automatically.

## 4. Native experiments and numerical checks, separately authorized

Only after separate Stage B authorization, restart MATLAB cleanly; set pkg/out as above, add only matlab/, and set `owner = fullfile(fileparts(pkg),'OWNER_SIMULATION.json');`. Execute sequentially, stopping at the first failure:

```matlab
phase4_run(out,owner,'nominal','base')
% Inspect/save genuine Scope evidence, then close_system('LRC_Phase4_PID_Isolated',0)
phase4_run(out,owner,'nominal','refined')
% Inspect, then close_system('LRC_Phase4_PID_Isolated',0)
phase4_run(out,owner,'stress','base')
% Inspect, then close_system('LRC_Phase4_PID_Isolated',0)
phase4_run(out,owner,'stress','refined')
% Inspect, then close_system('LRC_Phase4_PID_Isolated',0)
phase4_compare(out,owner,'convergence')
```

Each command writes a previously nonexistent run directory. It loads the saved model, verifies its hash/configuration, runs only the named scenario, saves complete native output and raw timeseries, records assessments and never saves the model after simulation. In desktop mode it leaves the model open for Scope inspection; close it without saving before the next run. Each run is1 s. Stress is the explicitly labelled8 V to1.53 V reference diagnostic, not load rejection or a master-specified waveform.

In desktop mode, inspect the retained native Scope traces immediately after each run. Save genuine screenshots/cursor notes before closing the model without saving. In non-desktop mode, the model closes automatically after a successful run. For durable review, retain the raw timeseries. Screenshots alone do not certify settling, and reopening the model must not be assumed to restore the original interactive traces. Use the existing result data for later plotting/inspection without rerunning. Write genuine observations/screenshots under out/scope_evidence/; identify native/explicit, time range, scenario and precision. Record only cursor readouts actually observed. The numerical tests remain primary evidence for the narrow performance margins.

## 5. Fresh-process saved-model reproduction

Exit MATLAB. Start a new MATLAB R2026a process, set pkg/out and the Stage B OWNER_SIMULATION.json path, and add matlab/ again:

```matlab
phase4_reopen(out,owner)
```

This loads the exact already-saved experiment, performs a single separately planned nominal refined reproduction, compares to the recorded refined run, and does not build/save a model. A changed time grid or mismatch fails visibly. Model hash remains anchored to build_record.json. Do not save a GUI change.

## 6. Collect existing evidence without altering it

```bash
python3 /absolute/path/LRC_Phase4_PID_Isolated_Validation_Package_v5/tools/collect_evidence.py \
  /absolute/path/P4_RUN_20261025_001 \
  /absolute/path/LRC_Phase4_PID_Evidence_001.zip
```

The collector refuses an existing output ZIP, hashes every existing result, checks the generated-model hash, and lists missing expected evidence. It creates only the new evidence ZIP, not an updated original manifest. It does not run anything or turn missing evidence into PASS. Return failed/incomplete evidence as-is if a test stopped.

## Expected result tree

- build_diary.txt, build_record.json, configuration_snapshot.json, newly generated LRC_Phase4_PID_Isolated.slx.
- nominal_base/, nominal_refined/, stress_base/, stress_refined/, nominal_fresh/: execution diary, run declaration, native_simulation.mat, raw_timeseries.mat, assessment.json, completion.json (or exception.txt).
- convergence_comparison.json, fresh_comparison.json, optional genuine scope_evidence/.
- Collected ZIP: existing evidence plus independent SHA256SUMS_EXPERIMENT.txt and collection-status inventory, never an altered historical native manifest.

An individual numerical check or all checks passing cannot authorize deployment, robustness claims, acceptance of the overall candidate, or completion of full Phase4. Stop after evidence collection and audit.

## V4 early supplemental approval validation

The unchanged stress-approval predicate runs immediately after scenario/precision validation, before run-directory creation, isolation setup, model loading, diary initialization, stress-specific configuration or simulation. Rejected stress approval therefore does not consume a single-use run directory through this execution path. Nominal remains independent of supplemental approval, subject to all existing Stage B, criteria and identity checks. Both default-disabled gates and the authorization template are unchanged.

The test harness retains all22 static/source-derived Boolean cases and adds7 ordering checks. Its regression check rejects the original late V3 placement. These are static tests, not MATLAB runtime tests or observed filesystem behavior in MATLAB. Run `python3 tools/test_authorization_static.py`. Current metadata and final logs describe V4; revision_evidence/V3_* retains prior release evidence. See V4_CHANGELOG.md and V4_SOURCE_DIFF.patch for the exact relocation. No native model was constructed, compiled or simulated.

## V5 native integrator-limit parameter correction

Read V5_LOCAL_PARAMETER_CORRECTION_ADDENDUM.md before any later owner-authorized construction. The verified-by-owner block exposes LimitIntegrator, not the former expected name. V5 changes only this configuration validation and adds assertions preserving its independent infinite upper/lower limits. Both LimitIntegrator and native LimitOutput remain off; the external actuator Saturation blocks remain unchanged. Run `python3 tools/test_native_parameters_static.py` for source-derived regression checks. All earlier authorization tests remain available.

Preserve the failed Stage A directory and original owner approval record unchanged. Do not resume or overwrite that partial model. Any later authorized V5 construction needs a fresh nonexistent P4_RUN_* sibling and a new Stage A record bound to the V5 manifest hash; simulation remains separately unauthorized. This release preparation does not authorize that construction or simulate anything.
