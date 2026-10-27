% LRC control model construction candidate. Requires MATLAB + Simulink.
% Run this script; it builds, checks the open-loop models, then adds control.
% No MATLAB response figures are created. See ENGINEERING_REPORT.md.
projectDir = fileparts(mfilename('fullpath'));
model = 'LRC_PID_Control';
target = fullfile(projectDir,[model '.slx']);
assert(license('test','Simulink'),'A Simulink license is required.');
assert(~verLessThan('matlab','9.1'),'Script-local functions require R2016b+.');
fprintf('MATLAB %s; release %s\n',version,version('-release'));
if bdIsLoaded(model)
    assert(strcmp(get_param(model,'Dirty'),'off'), ...
        'Unsaved model edits: save or close the model before rebuilding.');
    assert(strcmp(get_param(model,'Tag'),'LRC_Control_Candidate_v1'), ...
        'An unrelated model with this name is open.');
    close_system(model,0);
end
if isfile(target)
    load_system(target);
    assert(strcmp(get_param(model,'Tag'),'LRC_Control_Candidate_v1'), ...
        'Refusing to replace an unrelated model.');
    close_system(model,0);
end
p = parameters();
wn=sqrt(1/(p.L*p.C)); zeta=p.R_total/2*sqrt(p.C/p.L);
wd=wn*sqrt(1-zeta^2); poles=roots([p.L*p.C p.R_total*p.C 1]);
fprintf('wn=%.9f rad/s, zeta=%.9f, wd=%.9f rad/s\n',wn,zeta,wd);
fprintf('Poles %.9f +/- j%.9f; tp=%.9f s; OS=%.9f %%\n', ...
 real(poles(1)),abs(imag(poles(1))),pi/wd,100*exp(-pi*zeta/sqrt(1-zeta^2)));
assert(abs(wn-44.28)<.02 && abs(zeta-.5646)<.001 && abs(wd-36.55)<.02);
assert(abs(pi/wd-.086)<.001 && abs(100*exp(-pi*zeta/sqrt(1-zeta^2))-11.7)<.1);
load_system('simulink'); new_system(model);
set_param(model,'Tag','LRC_Control_Candidate_v1','Solver','ode45', ...
 'SolverType','Variable-step','MaxStep','0.001','RelTol','1e-8', ...
 'AbsTol','1e-10','StartTime','0','StopTime','1', ...
 'SignalLogging','on','SignalLoggingName','logsout','ReturnWorkspaceOutputs','on');
mw=get_param(model,'ModelWorkspace');
for n=fieldnames(p)'
    assignin(mw,n{1},p.(n{1})); assignin('base',n{1},p.(n{1}));
end
add(model,'Sources/Step','Input_voltage',[30 60 70 90], ...
 'Time','t_ei_step','Before','0','After','E_step');
add(model,'Sources/Step','Reference_step',[30 300 70 330], ...
 'Time','t_ref_step','Before','0','After','E_step');
add(model,'Sources/Step','Reference_return',[30 350 70 380], ...
 'Time','t_ref_return','Before','0','After','ref_return_delta');
add(model,'Math Operations/Sum','Reference',[100 325 125 365],'Inputs','++');
wire(model,'Reference_step/1','Reference/1');wire(model,'Reference_return/1','Reference/2');
add(model,'Sources/Step','Load_current',[30 430 70 460], ...
 'Time','t_load_step','Before','0','After','I_load_step');
add(model,'Sources/Constant','No_load',[30 140 70 170],'Value','0');
plant([model '/First_Principles_LRC_Plant'],[150 40 330 150]);
sub([model '/Canonical_Transfer_Function_Plant'],[150 190 330 260]);
b=[model '/Canonical_Transfer_Function_Plant'];
port(b,'In1','e_i',1,[25 45 55 65]);
add(b,'Continuous/Transfer Fcn','G',[100 30 250 80], ...
 'Numerator','1','Denominator','[L*C R_total*C 1]');
port(b,'Out1','e_o_TF',1,[300 45 330 65]);
wire(b,'e_i/1','G/1');wire(b,'G/1','e_o_TF/1');
wire(model,'Input_voltage/1','First_Principles_LRC_Plant/1','input_V');
wire(model,'No_load/1','First_Principles_LRC_Plant/2');
wire(model,'Input_voltage/1','Canonical_Transfer_Function_Plant/1');
logport(model,'First_Principles_LRC_Plant',1,'open_y_V');
logport(model,'Canonical_Transfer_Function_Plant',1,'tf_y_V');
for k=2:4
 add(model,'Sinks/Terminator',sprintf('OL_term%d',k),[370 100+k*25 390 120+k*25]);
 wire(model,sprintf('First_Principles_LRC_Plant/%d',k),sprintf('OL_term%d/1',k));
end
scope(model,'Model_Validation_Scope', ...
 {'Input_voltage/1','First_Principles_LRC_Plant/1','Canonical_Transfer_Function_Plant/1'}, ...
 [430 45 600 125],[1 1]);
% Phase gate: actual Simulink open-loop equivalence precedes controllers.
set_param(model,'SimulationCommand','update');
preflight=sim(model);
a=preflight.logsout.get('open_y_V').Values;
z=preflight.logsout.get('tf_y_V').Values;
zt=interp1(z.Time,z.Data,a.Time,'linear');
preflight_error=max(abs(a.Data-zt));
assert(preflight_error<1e-6,'Open-loop equivalence gate failed: %.9g V',preflight_error);
fprintf('Actual Simulink preflight max plant difference = %.9g V\n',preflight_error);
% Controller gains are analytically defined in parameters(), not tuned to traces.
closed=[model '/Closed_Loop_Controller_Comparison']; sub(closed,[180 330 440 530]);
port(closed,'In1','Reference',1,[20 30 50 50]);
port(closed,'In1','Load',2,[20 100 50 120]);
names={'P','PI','PID'};
for k=1:3
 b=[closed '/' names{k}]; branch(b,[100 30+(k-1)*180 290 160+(k-1)*180],names{k},false,false);
 wire(closed,'Reference/1',[names{k} '/1']); wire(closed,'Load/1',[names{k} '/2']);
 for j=1:6
  idx=(k-1)*6+j; out=sprintf('%s_%d',names{k},j);
  port(closed,'Out1',out,idx,[390 20+idx*28 420 40+idx*28]);
  wire(closed,sprintf('%s/%d',names{k},j),[out '/1']);
 end
end
wire(model,'Reference/1','Closed_Loop_Controller_Comparison/1','reference_V');
wire(model,'Load_current/1','Closed_Loop_Controller_Comparison/2','load_A');
for k=1:3
 for j=1:6
  suffix={'y_V','error_V','raw_V','u_V','current_A','integral_V'};
  logport(model,'Closed_Loop_Controller_Comparison',(k-1)*6+j,[names{k} '_' suffix{j}]);
 end
end
comparison=[model '/Native_Versus_Explicit_PID_Comparison'];sub(comparison,[180 620 440 800]);
port(comparison,'In1','Reference',1,[20 30 50 50]);port(comparison,'In1','Load',2,[20 100 50 120]);
cn={'Native_CT','Explicit_DT','Native_DT'};
for k=1:3
 branch([comparison '/' cn{k}],[100 30+(k-1)*180 300 160+(k-1)*180],'PID',k>1,k~=2);
 wire(comparison,'Reference/1',[cn{k} '/1']);wire(comparison,'Load/1',[cn{k} '/2']);
 for j=1:6
  idx=(k-1)*6+j;out=sprintf('%s_%d',cn{k},j);
  port(comparison,'Out1',out,idx,[400 20+idx*28 430 40+idx*28]);
  wire(comparison,sprintf('%s/%d',cn{k},j),[out '/1']);
 end
end
wire(model,'Reference/1','Native_Versus_Explicit_PID_Comparison/1');
wire(model,'Load_current/1','Native_Versus_Explicit_PID_Comparison/2');
for k=1:3
 for j=1:6
  logport(model,'Native_Versus_Explicit_PID_Comparison',(k-1)*6+j,[cn{k} '_' suffix{j}]);
 end
end
scope(model,'Open_vs_Closed_Loop_PID_Scope', ...
 {'Reference/1','First_Principles_LRC_Plant/1', ...
 'Closed_Loop_Controller_Comparison/1','Closed_Loop_Controller_Comparison/7', ...
 'Closed_Loop_Controller_Comparison/13'},[650 280 840 365],[1 1]);
add(model,'Signal Routing/Mux','Effort_traces',[530 420 535 530],'Inputs','4');
wire(model,'Closed_Loop_Controller_Comparison/15','Effort_traces/1');
wire(model,'Closed_Loop_Controller_Comparison/16','Effort_traces/2');
add(model,'Sources/Constant','Upper_limit',[450 490 490 510],'Value','U_max');
add(model,'Sources/Constant','Lower_limit',[450 540 490 560],'Value','U_min');
wire(model,'Upper_limit/1','Effort_traces/3','upper_limit_V');
wire(model,'Lower_limit/1','Effort_traces/4','lower_limit_V');
scope(model,'Internal_States_and_Control_Effort_Scope', ...
 {'Closed_Loop_Controller_Comparison/14','Effort_traces/1', ...
 'Closed_Loop_Controller_Comparison/17'},[650 420 840 530],[3 1]);
for mode=1:2
 if mode==1
  src={'Closed_Loop_Controller_Comparison/13','Native_Versus_Explicit_PID_Comparison/1', ...
  'Closed_Loop_Controller_Comparison/16','Native_Versus_Explicit_PID_Comparison/4'};
 else
  src={'Native_Versus_Explicit_PID_Comparison/7','Native_Versus_Explicit_PID_Comparison/13', ...
  'Native_Versus_Explicit_PID_Comparison/10','Native_Versus_Explicit_PID_Comparison/16'};
 end
 for j=1:2
  mux=sprintf('Compare_%d_%d',mode,j);add(model,'Signal Routing/Mux',mux,[530 600+mode*100+j*25 535 620+mode*100+j*25],'Inputs','2');
  wire(model,src{2*j-1},[mux '/1']);wire(model,src{2*j},[mux '/2']);
 end
 scope(model,sprintf('PID_Equivalence_%d_Scope',mode), ...
 {sprintf('Compare_%d_1/1',mode),sprintf('Compare_%d_2/1',mode)}, ...
 [650 600+mode*140 840 700+mode*140],[2 1]);
end
% Terminate unused logged output ports; these signals remain available in logsout.
blocks=find_system(model,'SearchDepth',1,'BlockType','SubSystem');
for k=1:numel(blocks)
 ph=get_param(blocks{k},'PortHandles');
 for j=1:numel(ph.Outport)
  if get_param(ph.Outport(j),'Line')==-1
   name=sprintf('Unused_%d_%d',k,j);
   add(model,'Sinks/Terminator',name,[930+k*30 20+j*25 945+k*30 35+j*25]);
   tp=get_param([model '/' name],'PortHandles');
   add_line(model,ph.Outport(j),tp.Inport,'autorouting','on');
  end
 end
end
Simulink.Annotation(model,sprintf(['LRC control candidate | zero ICs | capacitor-node load current\n' ...
 'Continuous plant, discrete PID Ts=0.01 s; all applied voltages pass through +/-5 V limits.\n' ...
 'PID design does NOT establish the 0.05 s settling target. Run run_lrc_verification.']));
logport(model,'Input_voltage',1,'input_V');
logport(model,'Reference',1,'reference_V');
logport(model,'Load_current',1,'load_A');
% Apply human-readable names after all routing is complete.
allports=find_system(model,'FindAll','on','Type','port','PortType','outport');
for k=1:numel(allports)
 if strcmp(get_param(allports(k),'DataLogging'),'on')
  lh=get_param(allports(k),'Line');
  if lh~=-1,set_param(lh,'Name',get_param(allports(k),'DataLoggingName'));end
 end
end
set_param(model,'SimulationCommand','update');
save_system(model,target);
open_system(model);
sc=find_system(model,'BlockType','Scope');for k=1:numel(sc),open_system(sc{k});end
fprintf('Saved %s\nRun run_lrc_verification for A-F, saturation recovery and reopen checks.\n',target);

function p=parameters()
p.R=10;p.R_eq=40;p.R_total=p.R+p.R_eq;p.L=1;p.C=510e-6;
p.E_step=1.53;p.Ts=.01;p.U_min=-5;p.U_max=5;
p.t_ref_step=0;p.t_ref_return=.4;p.ref_return_delta=0;p.t_ei_step=0;p.t_load_step=.5;p.I_load_step=0;
p.Kp_P=1; % choose 50 percent DC tracking ratio: Kp/(1+Kp)=0.5
% PI poles: -10 and the roots of s^2+40s+2000.
p.Kp_PI=p.L*p.C*(2000+10*40)-1;p.Ki_PI=p.L*p.C*10*2000;
p.desired_poles=[-38 -48 -58 -150];q=poly(p.desired_poles);
p.N_PID=q(2)-p.R_total/p.L;
p.Ki_PID=p.L*p.C*q(5)/p.N_PID;
p.Kp_PID=(p.L*p.C*q(4)-p.Ki_PID)/p.N_PID-1;
p.Kd_PID=(p.L*p.C*q(3)-p.R_total*p.C*p.N_PID-1-p.Kp_PID)/p.N_PID;
p.Kaw=20; % 0.05 s external back-calculation time constant; Ts*Kaw=0.2
fprintf('PID: Kp=%.12g Ki=%.12g Kd=%.12g N=%.12g\n',p.Kp_PID,p.Ki_PID,p.Kd_PID,p.N_PID);
end
function add(parent,lib,name,pos,varargin)
add_block(['simulink/' lib],[parent '/' name],'Position',pos,varargin{:});
end
function sub(path,pos)
add_block('built-in/Subsystem',path,'Position',pos);
end
function port(parent,kind,name,num,pos)
add_block(['built-in/' kind],[parent '/' name],'Port',num2str(num),'Position',pos);
end
function wire(parent,src,dst,name)
h=add_line(parent,src,dst,'autorouting','on');
if nargin==4,set_param(h,'Name',name);end
end
function logport(parent,block,num,name)
ph=get_param([parent '/' block],'PortHandles');h=ph.Outport(num);
set_param(h,'DataLogging','on','DataLoggingNameMode','Custom','DataLoggingName',name);
line=get_param(h,'Line');if line~=-1,set_param(line,'Name',name);end
end
function plant(path,pos)
sub(path,pos);port(path,'In1','e_i',1,[20 60 50 80]);port(path,'In1','i_load',2,[20 220 50 240]);
add(path,'Math Operations/Sum','KVL',[100 55 125 105],'Inputs','+--');
add(path,'Math Operations/Gain','inverse_L',[160 60 220 90],'Gain','1/L');
add(path,'Continuous/Integrator','i_series',[260 60 290 90],'InitialCondition','0');
add(path,'Math Operations/Gain','R_total',[260 145 320 175],'Gain','R_total');
add(path,'Math Operations/Sum','KCL',[360 65 385 105],'Inputs','+-');
add(path,'Math Operations/Gain','inverse_C',[420 65 480 95],'Gain','1/C');
add(path,'Continuous/Integrator','e_o',[520 65 550 95],'InitialCondition','0');
port(path,'Out1','voltage_V',1,[640 65 670 85]);port(path,'Out1','current_A',2,[640 135 670 155]);
port(path,'Out1','di_dt',3,[640 205 670 225]);port(path,'Out1','dv_dt',4,[640 275 670 295]);
wire(path,'e_i/1','KVL/1');wire(path,'R_total/1','KVL/2');wire(path,'e_o/1','KVL/3');
wire(path,'KVL/1','inverse_L/1');wire(path,'inverse_L/1','i_series/1');wire(path,'i_series/1','R_total/1');
wire(path,'i_series/1','KCL/1');wire(path,'i_load/1','KCL/2');wire(path,'KCL/1','inverse_C/1');
wire(path,'inverse_C/1','e_o/1');wire(path,'e_o/1','voltage_V/1');wire(path,'i_series/1','current_A/1');
wire(path,'inverse_L/1','di_dt/1');wire(path,'inverse_C/1','dv_dt/1');
end
function branch(path,pos,kind,discrete,native)
sub(path,pos);port(path,'In1','r',1,[20 40 50 60]);port(path,'In1','load',2,[20 380 50 400]);
plant([path '/Plant'],[660 80 810 220]);
add(path,'Math Operations/Sum','Error',[160 40 180 70],'Inputs','+-');
r='r/1';y='Plant/1';
if discrete
 add(path,'Discrete/Zero-Order Hold','Sample_reference',[75 35 120 65],'SampleTime','Ts');
 add(path,'Discrete/Zero-Order Hold','Sample_measurement',[90 220 135 250],'SampleTime','Ts');
 wire(path,r,'Sample_reference/1');wire(path,y,'Sample_measurement/1');r='Sample_reference/1';y='Sample_measurement/1';
end
wire(path,r,'Error/1');wire(path,y,'Error/2');
add(path,'Discontinuities/Saturation','Actuator',[540 80 600 130], ...
 'LowerLimit','U_min','UpperLimit','U_max');
if native
 add(path,'Continuous/PID Controller (2DOF)','Native_PID',[300 45 440 155]);
 b=[path '/Native_PID'];
 required={'Controller','Form','TimeDomain','P','I','D','N','b','c','TrackingMode','Kt','LimitOutput','UseKiTs','UseFilter', ...
 'InitialConditionForIntegrator','InitialConditionForFilter','IntegratorMethod','FilterMethod','SampleTime'};
 dp=get_param(b,'DialogParameters');assert(all(isfield(dp,required)), ...
  'This release lacks required native PID capabilities. See report.');
 set_param(b,'Controller','PID','Form','Parallel','TimeDomain','Continuous-time', ...
  'P','Kp_PID','I','Ki_PID','D','Kd_PID','N','N_PID','b','1','c','0', ...
  'TrackingMode','on','Kt','Kaw','LimitOutput','off','UseFilter','on','UseKiTs','off', ...
  'InitialConditionForIntegrator','0','InitialConditionForFilter','0');
 if discrete
  set_param(b,'TimeDomain','Discrete-time','SampleTime','Ts', ...
   'IntegratorMethod','Forward Euler','FilterMethod','Backward Euler');
 end
 wire(path,r,'Native_PID/1');wire(path,y,'Native_PID/2');wire(path,'Actuator/1','Native_PID/3');
 raw='Native_PID/1';
 % Native integral state is not claimed as observed: output NaN explicitly.
 add(path,'Sources/Constant','Integral_unavailable',[360 310 430 340],'Value','NaN');istate='Integral_unavailable/1';
else
 controller([path '/Explicit'],[250 40 440 210],kind,discrete);
 wire(path,'Error/1','Explicit/1');wire(path,y,'Explicit/2');wire(path,'Actuator/1','Explicit/3');
 raw='Explicit/1';istate='Explicit/2';
end
wire(path,raw,'Actuator/1');wire(path,'Actuator/1','Plant/1');wire(path,'load/1','Plant/2');
% Physical equation signals logged directly, for residual checks.
logport(path,'Plant',3,[strrep(get_param(path,'Name'),' ','_') '_di_dt']);
logport(path,'Plant',4,[strrep(get_param(path,'Name'),' ','_') '_dv_dt']);
for k=3:4
 add(path,'Sinks/Terminator',sprintf('Derivative%d',k),[840 240+k*30 860 260+k*30]);
 wire(path,sprintf('Plant/%d',k),sprintf('Derivative%d/1',k));
end
% Error output is continuous physical tracking error, even for discrete PID.
add(path,'Math Operations/Sum','Physical_error',[680 300 705 330],'Inputs','+-');
wire(path,'r/1','Physical_error/1');wire(path,'Plant/1','Physical_error/2');
ss={'Plant/1','Physical_error/1',raw,'Actuator/1','Plant/2',istate};
for k=1:6
 out=sprintf('out%d',k);port(path,'Out1',out,k,[940 25+k*55 970 45+k*55]);wire(path,ss{k},[out '/1']);
end
end
function controller(path,pos,kind,dt)
sub(path,pos);port(path,'In1','error',1,[20 40 50 60]);port(path,'In1','measurement',2,[20 280 50 300]);port(path,'In1','applied',3,[20 170 50 190]);
add(path,'Math Operations/Gain','P',[130 35 195 65],'Gain',['Kp_' kind]);
wire(path,'error/1','P/1');add(path,'Math Operations/Sum','Raw',[580 50 610 110],'Inputs','+++');wire(path,'P/1','Raw/1');
if strcmp(kind,'P')
 add(path,'Sources/Constant','Integral',[400 150 440 180],'Value','0');
 add(path,'Sources/Constant','Derivative',[400 280 440 310],'Value','0');
 add(path,'Sinks/Terminator','No_AW',[100 170 120 190]);wire(path,'applied/1','No_AW/1');
else
 add(path,'Math Operations/Gain','Ki',[130 85 195 115],'Gain',['Ki_' kind]);wire(path,'error/1','Ki/1');
 add(path,'Math Operations/Sum','Saturation_difference',[130 155 160 195],'Inputs','+-');
 wire(path,'applied/1','Saturation_difference/1');wire(path,'Raw/1','Saturation_difference/2');
 add(path,'Math Operations/Gain','Back_calculation',[200 155 260 185],'Gain','Kaw');wire(path,'Saturation_difference/1','Back_calculation/1');
 add(path,'Math Operations/Sum','I_rate',[290 95 320 135],'Inputs','++');
 wire(path,'Ki/1','I_rate/1');wire(path,'Back_calculation/1','I_rate/2');
 if dt
  add(path,'Math Operations/Gain','Ts_gain',[340 95 385 125],'Gain','Ts');wire(path,'I_rate/1','Ts_gain/1');
  add(path,'Math Operations/Sum','I_next',[410 85 435 125],'Inputs','++');wire(path,'Ts_gain/1','I_next/1');
  add(path,'Discrete/Unit Delay','Integral',[470 155 510 185],'SampleTime','Ts','InitialCondition','0');
  wire(path,'I_next/1','Integral/1');wire(path,'Integral/1','I_next/2');
 else
  add(path,'Continuous/Integrator','Integral',[410 95 440 125],'InitialCondition','0');wire(path,'I_rate/1','Integral/1');
 end
 if strcmp(kind,'PID')
  if dt
   add(path,'Discrete/Unit Delay','Filter_memory',[340 360 380 390],'SampleTime','Ts','InitialCondition','0');
   add(path,'Math Operations/Gain','Filter_a',[410 360 470 390],'Gain','1/(1+N_PID*Ts)');
   add(path,'Math Operations/Gain','Filter_b',[140 360 210 390],'Gain','N_PID*Ts/(1+N_PID*Ts)');
   add(path,'Math Operations/Sum','Filter_next',[260 350 290 390],'Inputs','++');
   wire(path,'measurement/1','Filter_b/1');wire(path,'Filter_b/1','Filter_next/1');
   wire(path,'Filter_memory/1','Filter_a/1');wire(path,'Filter_a/1','Filter_next/2');wire(path,'Filter_next/1','Filter_memory/1');
   add(path,'Math Operations/Sum','D_difference',[140 270 170 310],'Inputs','+-');
   wire(path,'measurement/1','D_difference/1');wire(path,'Filter_memory/1','D_difference/2');
   add(path,'Math Operations/Gain','Derivative',[240 270 330 310],'Gain','-Kd_PID*N_PID/(1+N_PID*Ts)');
   wire(path,'D_difference/1','Derivative/1');
  else
   add(path,'Math Operations/Gain','minus_Kd',[100 270 170 300],'Gain','-Kd_PID');
   add(path,'Math Operations/Sum','D_difference',[220 265 245 305],'Inputs','+-');
   add(path,'Math Operations/Gain','Derivative',[290 270 350 300],'Gain','N_PID');
   add(path,'Continuous/Integrator','Filter_state',[390 350 420 380],'InitialCondition','0');
   wire(path,'measurement/1','minus_Kd/1');wire(path,'minus_Kd/1','D_difference/1');
   wire(path,'Filter_state/1','D_difference/2');wire(path,'D_difference/1','Derivative/1');wire(path,'Derivative/1','Filter_state/1');
  end
 else
  add(path,'Sources/Constant','Derivative',[400 280 440 310],'Value','0');
 end
end
if ~strcmp(kind,'PID')
 add(path,'Sinks/Terminator','No_derivative',[100 280 120 300]);wire(path,'measurement/1','No_derivative/1');
end
wire(path,'Integral/1','Raw/2');wire(path,'Derivative/1','Raw/3');
port(path,'Out1','raw',1,[680 70 710 90]);port(path,'Out1','integral_state',2,[680 160 710 180]);
wire(path,'Raw/1','raw/1');wire(path,'Integral/1','integral_state/1');
end
function scope(model,name,src,pos,layout)
add(model,'Sinks/Scope',name,pos,'NumInputPorts',num2str(numel(src)));
b=[model '/' name];cfg=get_param(b,'ScopeConfiguration');
assert(isprop(cfg,'LayoutDimensions') && isprop(cfg,'OpenAtSimulationStart'), ...
 'Unsupported Scope configuration API; no Scope properties silently skipped.');
cfg.LayoutDimensions=layout;cfg.OpenAtSimulationStart=true;
for displayIndex=1:prod(layout)
 cfg.ActiveDisplay=num2str(displayIndex);cfg.ShowLegend=true;cfg.ShowGrid=true;
end
cfg.TimeSpan='1';cfg.AxesScaling='Auto';cfg.TimeUnits='Seconds';
for displayIndex=1:prod(layout)
 cfg.ActiveDisplay=num2str(displayIndex);cfg.YLabel='Voltage (V)';
 if strcmp(name,'Internal_States_and_Control_Effort_Scope') && displayIndex==3
  cfg.YLabel='Series current (A)';
 end
end
if isprop(cfg,'ShowGrid'),cfg.ShowGrid=true;
else,error('Scope ShowGrid capability missing in this release.');end
for k=1:numel(src),wire(model,src{k},sprintf('%s/%d',name,k));end
end
