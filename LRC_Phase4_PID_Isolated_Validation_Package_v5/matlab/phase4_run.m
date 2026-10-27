function phase4_run(out,approval,scenario,precision)
% EXECUTION ENTRY POINT. Never called by package preparation or integrity tools.
% Allowed scenario: nominal / stress. Precision: base / refined / fresh.
[pkg,owner]=p4_guard(approval,'simulation',out); %#ok<ASGLU>
assert(any(strcmp(scenario,{'nominal','stress'})) && any(strcmp(precision,{'base','refined','fresh'})));
if strcmp(precision,'fresh'), assert(strcmp(scenario,'nominal'),'Fresh check uses nominal'); end
if strcmp(scenario,'stress')
 assert(isfield(owner,'supplemental_stress_approved') && islogical(owner.supplemental_stress_approved) && isscalar(owner.supplemental_stress_approved) && isequal(owner.supplemental_stress_approved,true),'Diagnostic stress requires explicit logical-scalar true approval');
end
rundir=fullfile(out,[scenario '_' precision]); assert(~isfolder(rundir),'Run exists. Refusing overwrite');
[parent,leaf]=fileparts(out);
assert(strcmp(char(java.io.File(parent).getCanonicalPath),char(java.io.File(fileparts(pkg)).getCanonicalPath)) && startsWith(leaf,'P4_RUN_'),'Wrong experiment directory');
build=jsondecode(fileread(fullfile(out,'build_record.json'))); m=build.model;
assert(strcmp(m,'LRC_Phase4_PID_Isolated') && strcmp(build.source_sha256, ...
 '3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1'),'Wrong build identity');
modelFile=fullfile(out,[m '.slx']); assert(strcmp(p4_hash(modelFile),build.model_sha256),'Wrong/changed generated model');
assert(~bdIsLoaded(m),'Close model without saving, then use a clean MATLAB process');
mkdir(rundir); isolation=p4_isolate(rundir); %#ok<NASGU>
load_system(modelFile); % Remain open in desktop mode for genuine Scope inspection; never save.
actual=p4_snapshot(m); expected=jsondecode(fileread(fullfile(out,'configuration_snapshot.json')));
assert(isequaln(jsondecode(jsonencode(actual)),expected),'Model configuration/connection fingerprint mismatch');
assert(strcmp(get_param(m,'Dirty'),'off'),'Saved model dirtied during load');
diary(fullfile(rundir,'execution_diary.txt')); cleanupDiary=onCleanup(@()diary('off'));
p=p4_constants;
if strcmp(precision,'base'), maxstep=2e-6; rel=1e-9; absTol=1e-11;
else, maxstep=1e-6; rel=1e-11; absTol=1e-13; end
in=Simulink.SimulationInput(m);
in=in.setModelParameter('Solver','ode15s','MaxStep',sprintf('%.17g',maxstep), ...
 'RelTol',sprintf('%.17g',rel),'AbsTol',sprintf('%.17g',absTol),'StopTime','1','CaptureErrors','on');
if strcmp(scenario,'stress')
 in=in.setBlockParameter([m '/Reference'],'After','8');
 in=in.setBlockParameter([m '/Return'],'After',sprintf('%.17g',p.r-8));
end
p4_json(fullfile(rundir,'run_declaration.json'),struct('scenario',scenario,'precision',precision, ...
 'maxstep',maxstep,'RelTol',rel,'AbsTol',absTol,'parameters',p,'owner',owner, ...
 'approval_stage','simulation','approval_record_sha256',p4_hash(approval), ...
 'package_manifest_sha256',owner.package_manifest_sha256, ...
 'test_register_sha256',owner.test_register_sha256,'build_record_sha256',owner.build_record_sha256, ...
 'model_sha256_before',p4_hash(modelFile),'release',version,'status','STARTED_NOT_YET_PASSED'));
try
 result=sim(in); %#ok<NASGU> ONLY NATIVE EXECUTION CALL; owner must authorize before invoking this function.
 save(fullfile(rundir,'native_simulation.mat'),'result','p','scenario','precision','-v7.3');
 if ~isempty(result.ErrorMessage), error('Phase4:Simulation','%s',result.ErrorMessage); end
 raw=struct; tags={'CE','CN','DE','DN'}; signals={'y','i','raw','applied','aw','I','f','D','error','ref'};
 for k=1:4
  for j=1:numel(signals)
   name=[tags{k} '_' signals{j}]; ts=result.get(name);
   assert(isa(ts,'timeseries'),'Missing native timeseries %s',name);
   raw.(name)=ts;
  end
 end
 save(fullfile(rundir,'raw_timeseries.mat'),'raw','-v7.3');
 report=p4_assess(raw,scenario,maxstep);
 p4_json(fullfile(rundir,'assessment.json'),report);
 assert(strcmp(p4_hash(modelFile),build.model_sha256),'Saved model changed during execution');
 p4_json(fullfile(rundir,'completion.json'),struct('completed',true,'model_sha256_after',p4_hash(modelFile), ...
  'numerical_checks_pass',report.all_checks_pass,'status','AWAITING_CONVERGENCE_FRESH_PROCESS_AND_OWNER_AUDIT'));
 assert(report.all_checks_pass,'Phase4:Checks','One or more checks failed; evidence retained, do not overwrite');
catch err
 f=fopen(fullfile(rundir,'exception.txt'),'w'); fprintf(f,'%s\n',getReport(err,'extended','hyperlinks','off')); fclose(f);
 rethrow(err);
end
if ~usejava('desktop'), close_system(m,0); end
fprintf('Run recorded. No overall acceptance or robustness claim. Model NOT saved after simulation.\n');
if usejava('desktop'), fprintf('Inspect Scopes now, then close_system(''%s'',0) before the next run.\n',m); end
end
