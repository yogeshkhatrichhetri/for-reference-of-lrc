function phase4_build(out,approval)
% CONSTRUCTION ONLY. Never invokes sim. Run only after separate owner authorization.
[pkg,owner]=p4_guard(approval,'construction');
assert(java.io.File(out).isAbsolute(),'Use an absolute experiment path');
assert(~isfolder(out) && ~isfile(out),'Output already exists; nothing overwritten');
[parent,leaf]=fileparts(out); assert(strcmp(char(java.io.File(parent).getCanonicalPath), ...
 char(java.io.File(fileparts(pkg)).getCanonicalPath)) && startsWith(leaf,'P4_RUN_'), ...
 'Use a new P4_RUN_* sibling of this package.');
assert(isempty(find_system('type','block_diagram')),'Use a clean MATLAB session before construction.');
mkdir(out); isolation=p4_isolate(out); %#ok<NASGU>
diary(fullfile(out,'build_diary.txt')); cleanup=onCleanup(@()diary('off'));
p=p4_constants; source=fullfile(pkg,'baseline','LRC_Phase2_OpenLoop.slx');
sourceHash=p4_hash(source); load_system(source); sm='LRC_Phase2_OpenLoop';
closeSource=onCleanup(@()close_system(sm,0));
assert(strcmp(get_param(sm,'Dirty'),'off'),'Source dirty on load; stop');
assert(strcmp(get_param([sm '/Physical_LRC/invL'],'Gain'),'1/L'));
assert(strcmp(get_param([sm '/Physical_LRC/invC'],'Gain'),'1/C'));
assert(strcmp(get_param([sm '/Physical_LRC/Resistance'],'Gain'),'R+Req'));
assert(strcmp(get_param([sm '/Physical_LRC/KVL'],'Inputs'),'+--'));
assert(strcmp(get_param([sm '/Physical_LRC/KCL'],'Inputs'),'+-'));
assert(strcmp(get_param([sm '/Physical_LRC/i'],'InitialCondition'),'0'));
assert(strcmp(get_param([sm '/Physical_LRC/v'],'InitialCondition'),'0'));
m='LRC_Phase4_PID_Isolated'; assert(~bdIsLoaded(m) && isempty(which([m '.slx'])),'Model name collision');
load_system('simulink'); new_system(m); mw=get_param(m,'ModelWorkspace');
for n=fieldnames(p)', assignin(mw,n{1},p.(n{1})); end
set_param(m,'Solver','ode15s','SolverType','Variable-step','MaxStep','2e-6', ...
 'RelTol','1e-9','AbsTol','1e-11','StartTime','0','StopTime','1', ...
 'ReturnWorkspaceOutputs','on','SaveTime','on','SaveState','on','StateSaveName','xout', ...
 'SaveFormat','Dataset','LimitDataPoints','off','SimulationMode','normal');
add(m,'Sources/Step','Reference',[20 20 65 50],'Time','0','Before','0','After','r','SampleTime','0');
add(m,'Sources/Step','Return',[20 80 65 110],'Time','0.2','Before','0','After','0','SampleTime','0');
add(m,'Math Operations/Sum','Reference_sum',[110 20 140 65],'Inputs','++');
wire(m,'Reference/1','Reference_sum/1'); wire(m,'Return/1','Reference_sum/2');
add(m,'Sources/Constant','Zero_load',[20 160 65 190],'Value','0');
tags={'CE','CN','DE','DN'};
for k=1:4
 tag=tags{k}; discrete=k>2; native=mod(k,2)==0; y0=240*(k-1)+100;
 % Copy the exact audited physical subsystem; no source save, no source controller reused.
 add_block([sm '/Physical_LRC'],[m '/' tag '_Plant'],'Position',[580 y0 730 y0+100]);
 c=[m '/' tag '_Controller']; add_block('built-in/Subsystem',c,'Position',[280 y0 450 y0+100]);
 controller(c,discrete,native);
 add(m,'Discontinuities/Saturation',[tag '_Actuator'],[490 y0 540 y0+40], ...
  'LowerLimit','umin','UpperLimit','umax');
 ref='Reference_sum/1'; meas=[tag '_Plant/1'];
 if discrete
  add(m,'Discrete/Zero-Order Hold',[tag '_Reference_sample'],[170 y0 215 y0+30],'SampleTime','Ts');
  add(m,'Discrete/Zero-Order Hold',[tag '_Measurement_sample'],[770 y0 815 y0+30],'SampleTime','Ts');
  wire(m,ref,[tag '_Reference_sample/1']); wire(m,meas,[tag '_Measurement_sample/1']);
  ref=[tag '_Reference_sample/1']; meas=[tag '_Measurement_sample/1'];
 end
 wire(m,ref,[tag '_Controller/1']); wire(m,meas,[tag '_Controller/2']);
 wire(m,[tag '_Controller/1'],[tag '_Actuator/1']);
 wire(m,[tag '_Actuator/1'],[tag '_Plant/1']); wire(m,'Zero_load/1',[tag '_Plant/2']);
 wire(m,[tag '_Actuator/1'],[tag '_Controller/3']);
 signals={'y','i','raw','applied','aw','I','f','D','error','ref'};
 sources={[tag '_Plant/1'],[tag '_Plant/2'],[tag '_Controller/1'],[tag '_Actuator/1'], ...
  [tag '_Controller/2'],[tag '_Controller/3'],[tag '_Controller/4'], ...
  [tag '_Controller/5'],[tag '_Controller/6'],ref};
 add(m,'Sinks/Scope',[tag '_Scope'],[1040 y0 1100 y0+80],'NumInputPorts','5');
 cfg=get_param([m '/' tag '_Scope'],'ScopeConfiguration');
 cfg.OpenAtSimulationStart=true; cfg.ShowLegend=true; cfg.ShowGrid=true; cfg.TimeSpan='1';
 for j=1:numel(signals)
  logname=[tag '_' signals{j}];
  add(m,'Sinks/To Workspace',['Log_' logname],[850+j*10 y0+j*14 1000+j*10 y0+12+j*14], ...
   'VariableName',logname,'SaveFormat','Timeseries','MaxDataPoints','inf','Decimation','1','SampleTime','0');
  h=wire(m,sources{j},['Log_' logname '/1']); set_param(h,'Name',logname);
  if j<=5, wire(m,sources{j},[tag '_Scope/' num2str(j)]); end
 end
end
% Runtime compile and required-port checks happen only on the owner's machine.
set_param(m,'SimulationCommand','update');
assert(strcmp(get_param(sm,'Dirty'),'off'),'Audited source was dirtied; do not save it');
assert(strcmp(p4_hash(source),sourceHash),'Source bytes changed');
modelFile=fullfile(out,[m '.slx']); save_system(m,modelFile);
s=p4_snapshot(m); p4_json(fullfile(out,'configuration_snapshot.json'),s);
p4_json(fullfile(out,'build_record.json'),struct('model',m,'model_sha256',p4_hash(modelFile), ...
 'source_sha256',sourceHash,'matlab',version,'products',ver,'owner',owner, ...
 'approval_stage','construction','approval_record_sha256',p4_hash(approval), ...
 'package_manifest_sha256',p4_hash(fullfile(pkg,'SHA256SUMS.txt')), ...
 'test_register_sha256',p4_hash(fullfile(pkg,'TEST_REGISTER.md')), ...
 'source_relation','Physical_LRC copied with add_block; independent new controller paths; source never saved', ...
 'status','CONSTRUCTED_AND_COMPILED_ONLY_NOT_SIMULATED'));
close_system(m,0);
fprintf('Construction complete. Simulations UNVERIFIED. Overall NOT ACCEPTED.\n');
end
function controller(c,discrete,native)
for j=1:3, port(c,'In1',sprintf('in%d',j),j); end
for j=1:6, port(c,'Out1',sprintf('out%d',j),j); end
add(c,'Math Operations/Sum','error',[90 20 120 55],'Inputs','+-');
wire(c,'in1/1','error/1'); wire(c,'in2/1','error/2');
add(c,'Math Operations/Gain','P',[150 20 190 50],'Gain','Kp'); wire(c,'error/1','P/1');
add(c,'Math Operations/Sum','filter_difference',[90 130 120 165],'Inputs','+-');
wire(c,'in2/1','filter_difference/1');
if discrete
 add(c,'Discrete/Unit Delay','f_state',[250 160 290 190],'SampleTime','Ts','InitialCondition','0');
 add(c,'Math Operations/Gain','filter_alpha',[90 210 130 240],'Gain','alpha');
 add(c,'Math Operations/Gain','filter_feed',[90 260 130 290],'Gain','1-alpha');
 add(c,'Math Operations/Sum','filter_next',[180 210 210 250],'Inputs','++');
 wire(c,'f_state/1','filter_alpha/1'); wire(c,'in2/1','filter_feed/1');
 wire(c,'filter_alpha/1','filter_next/1'); wire(c,'filter_feed/1','filter_next/2');
 wire(c,'filter_next/1','f_state/1'); dg='-beta';
else
 add(c,'Math Operations/Gain','filter_N',[150 130 190 160],'Gain','N');
 add(c,'Continuous/Integrator','f_state',[250 160 290 190],'InitialCondition','0');
 wire(c,'filter_difference/1','filter_N/1'); wire(c,'filter_N/1','f_state/1'); dg='-Kd*N';
end
wire(c,'f_state/1','filter_difference/2');
add(c,'Math Operations/Gain','D',[330 130 380 160],'Gain',dg); wire(c,'filter_difference/1','D/1');
add(c,'Math Operations/Sum','aw_difference',[520 300 550 335],'Inputs','+-');
add(c,'Math Operations/Gain','AW',[590 300 630 330],'Gain','Kaw');
wire(c,'in3/1','aw_difference/1'); wire(c,'aw_difference/1','AW/1');
if native
 add(c,'Continuous/PID Controller (2DOF)','Native_PID',[350 30 460 100]);
 b=[c '/Native_PID']; dp=get_param(b,'DialogParameters');
 required={'Controller','Form','TimeDomain','P','I','D','N','b','c','TrackingMode','Kt', ...
 'LimitOutput','UseKiTs','UseFilter','InitialConditionForIntegrator','InitialConditionForFilter', ...
 'IntegratorMethod','FilterMethod','SampleTime','ExternalReset','ControllerParametersSource', ...
 'InitialConditionSource','LimitIntegrator','UseExternalTs', ...
 'UpperIntegratorSaturationLimit','LowerIntegratorSaturationLimit'};
 assert(all(isfield(dp,required)),'Required native parameters missing; STOP this branch, no substitute');
 % Integrator limits are separate from the native controller-output limit flag.
 upperIntegratorLimit=get_param(b,'UpperIntegratorSaturationLimit');
 lowerIntegratorLimit=get_param(b,'LowerIntegratorSaturationLimit');
 assert(isequal(str2double(upperIntegratorLimit),Inf) && isequal(str2double(lowerIntegratorLimit),-Inf), ...
  'Unexpected integrator limit defaults; STOP without replacing them');
 set_param(b,'Controller','PID','Form','Parallel','TimeDomain','Continuous-time', ...
  'ControllerParametersSource','internal','InitialConditionSource','internal', ...
  'LimitIntegrator','off','UseExternalTs','off', ...
  'P','Kp','I','Ki','D','Kd','N','N','b','1','c','0','TrackingMode','on','Kt','Kaw', ...
  'LimitOutput','off','UseKiTs','off','UseFilter','on','ExternalReset','none', ...
  'InitialConditionForIntegrator','0','InitialConditionForFilter','0');
 if discrete
  set_param(b,'TimeDomain','Discrete-time','SampleTime','Ts', ...
   'IntegratorMethod','Forward Euler','FilterMethod','Backward Euler');
 end
 assert(strcmp(get_param(b,'LimitIntegrator'),'off'),'Integrator saturation must be disabled');
 assert(strcmp(get_param(b,'LimitOutput'),'off'),'Native output limiting must remain disabled; external actuator saturation applies');
 assert(isequal(str2double(get_param(b,'UpperIntegratorSaturationLimit')),str2double(upperIntegratorLimit)) && ...
  isequal(str2double(get_param(b,'LowerIntegratorSaturationLimit')),str2double(lowerIntegratorLimit)), ...
  'Integrator limit defaults changed during configuration');
 ph=get_param(b,'PortHandles'); assert(numel(ph.Inport)==3 && numel(ph.Outport)==1,'Unexpected native port layout');
 wire(c,'in1/1','Native_PID/1'); wire(c,'in2/1','Native_PID/2'); wire(c,'in3/1','Native_PID/3');
 raw='Native_PID/1';
 % This is a reconstruction from output and independent filter observer, NOT a measured native I state.
 add(c,'Math Operations/Sum','I_reconstructed',[530 70 570 120],'Inputs','+--');
 wire(c,raw,'I_reconstructed/1'); wire(c,'P/1','I_reconstructed/2'); wire(c,'D/1','I_reconstructed/3');
 Is='I_reconstructed/1';
else
 add(c,'Math Operations/Gain','Ki_gain',[150 330 190 360],'Gain','Ki'); wire(c,'error/1','Ki_gain/1');
 add(c,'Math Operations/Sum','I_rate',[250 330 280 370],'Inputs','++');
 wire(c,'Ki_gain/1','I_rate/1'); wire(c,'AW/1','I_rate/2');
 if discrete
  add(c,'Math Operations/Gain','Ts_gain',[310 330 350 360],'Gain','Ts');
  add(c,'Math Operations/Sum','I_next',[390 330 420 370],'Inputs','++');
  add(c,'Discrete/Unit Delay','I_state',[450 400 490 430],'SampleTime','Ts','InitialCondition','0');
  wire(c,'I_rate/1','Ts_gain/1'); wire(c,'Ts_gain/1','I_next/1');
  wire(c,'I_state/1','I_next/2'); wire(c,'I_next/1','I_state/1');
 else
  add(c,'Continuous/Integrator','I_state',[450 400 490 430],'InitialCondition','0');
  wire(c,'I_rate/1','I_state/1');
 end
 add(c,'Math Operations/Sum','raw',[430 20 470 70],'Inputs','+++');
 wire(c,'P/1','raw/1'); wire(c,'I_state/1','raw/2'); wire(c,'D/1','raw/3');
 raw='raw/1'; Is='I_state/1';
end
wire(c,raw,'aw_difference/2');
src={raw,'AW/1',Is,'f_state/1','D/1','error/1'};
for j=1:6, wire(c,src{j},sprintf('out%d/1',j)); end
end
function add(m,lib,n,pos,varargin)
add_block(['simulink/' lib],[m '/' n],'Position',pos,varargin{:});
end
function port(m,kind,n,k)
assert(any(strcmp(kind,{'In1','Out1'})));
add_block(['simulink/Ports & Subsystems/' kind],[m '/' n],'Port',num2str(k),'Position',[20 30*k 40 30*k+15]);
end
function h=wire(m,s,d)
h=add_line(m,s,d,'autorouting','on');
end
