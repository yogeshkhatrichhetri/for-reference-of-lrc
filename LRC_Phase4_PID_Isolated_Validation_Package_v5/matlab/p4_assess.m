function report=p4_assess(raw,scenario,maxstep)
p=p4_constants; tags={'CE','CN','DE','DN'};
names={'y','i','raw','applied','aw','I','f','D','error','ref'};
report=struct('classification','NATIVE_LOG_MEASUREMENTS_WITH_SEPARATELY_LABELLED_ANALYTICAL_BOUNDS', ...
 'scenario',scenario,'checks',struct([])); checks=struct([]); traces=struct;
for k=1:4
 tag=tags{k}; t=raw.([tag '_y']).Time(:); s=struct;
 assert(isreal(t) && all(isfinite(t)) && all(diff(t)>=0) && numel(t)>100,'Invalid timestamps');
 for j=1:numel(names)
  ts=raw.([tag '_' names{j}]); v=reshape(ts.Data,[],1);
  assert(isequal(ts.Time(:),t),'Unaligned logging: do not interpolate over controller events');
  assert(isreal(v) && all(isfinite(v)) && numel(v)==numel(t),'Invalid/missing signal');
  s.(names{j})=v;
 end
 % Duplicate event timestamps are retained in raw data. Metrics use post-event values at each time.
 [t,idx]=unique(t,'last');
 for j=1:numel(names), s.(names{j})=s.(names{j})(idx); end
 assert(abs(t(1))<1e-12 && abs(t(end)-1)<1e-12 && max(diff(t))<=maxstep*1.00001, ...
  'Timing or resolution mismatch');
 expected=p.r*ones(size(t)); if strcmp(scenario,'stress'), expected(t<.2)=8; end
 addcheck([tag '_reference'],max(abs(s.ref-expected)),1e-10,false);
 addcheck([tag '_zero_initial_plant'],max(abs([s.y(1) s.i(1)])),1e-12,false);
 addcheck([tag '_applied_rails'],max(abs(s.applied)),5,false);
 addcheck([tag '_saturation_equation'],max(abs(s.applied-min(5,max(-5,s.raw)))),1e-10,false);
 addcheck([tag '_backcalculation_equation'],max(abs(s.aw-p.Kaw*(s.applied-s.raw))),1e-8,false);
 discrete=k>2;
 if discrete
  hit=(0:p.Ts:1)'; indices=zeros(size(hit));
  for j=1:numel(hit)
   [d,indices(j)]=min(abs(t-hit(j))); assert(d<1e-11,'Controller event not logged exactly');
  end
  q=struct; for j=1:numel(names), q.(names{j})=s.(names{j})(indices); end
  addcheck([tag '_sampled_error'],max(abs(q.error-(q.ref-q.y))),1e-10,false);
  addcheck([tag '_FE_integral_update'],max(abs(diff(q.I)-p.Ts*(p.Ki*q.error(1:end-1)+q.aw(1:end-1)))),1e-8,false);
  addcheck([tag '_BE_filter_update'],max(abs(q.f(2:end)-p.alpha*q.f(1:end-1)-(1-p.alpha)*q.y(1:end-1))),1e-10,false);
  addcheck([tag '_derivative_convention'],max(abs(q.D+p.beta*(q.y-q.f))),1e-8,false);
  addcheck([tag '_raw_reconstruction'],max(abs(q.raw-(p.Kp*q.error+q.I+q.D))),1e-8,false);
  held=zeros(size(t));
  for j=1:numel(indices)-1, held(indices(j):indices(j+1)-1)=q.applied(j); end
  held(indices(end):end)=q.applied(end);
  addcheck([tag '_zero_order_hold'],max(abs(s.applied-held)),1e-9,false);
 else
  addcheck([tag '_continuous_error'],max(abs(s.error-(s.ref-s.y))),1e-10,false);
  addcheck([tag '_derivative_convention'],max(abs(s.D+p.Kd*p.N*(s.y-s.f))),1e-8,false);
  % Integral-state reconstruction on native branch is NOT a direct native state measurement.
  irate=p.Ki*s.error+s.aw; integ=cumtrapz(t,irate);
  addcheck([tag '_integral_trajectory_residual'],max(abs(s.I-s.I(1)-integ)),1e-3,false);
 end
 addcheck([tag '_zero_controller_states'],max(abs([s.I(1) s.f(1)])),1e-9,false);
 x=[s.i(end);s.y(end);s.I(end);s.f(end)]; tail=p4_tail(x,discrete);
 report.(tag).tail=tail;
 addcheck([tag '_stable_linearization'],double(~tail.stable),0,false);
 addcheck([tag '_conditional_future_tail'],double(~tail.bound_pass),0,false);
 % Global plant acceleration bound for any |u|<=5, zero plant states:
 % |i|<=5 sqrt(1+(sigma/wd)^2)/(L sigma); |y|<=5/(L C wd sigma).
 sigma=(p.R+p.Req)/(2*p.L); wd=sqrt(1/(p.L*p.C)-sigma^2);
 ib=5*sqrt(1+(sigma/wd)^2)/(p.L*sigma); yb=5/(p.L*p.C*wd*sigma);
 M=(5+(p.R+p.Req)*ib+yb)/(p.L*p.C);
 segmentError=M*diff(t).^2/8; % linear-interpolant error for continuous capacitor voltage
 [peak,jpeak]=max(s.y); peakUpper=max(max(s.y(1:end-1),s.y(2:end))+segmentError);
 last=find(min(s.y(1:end-1),s.y(2:end))-segmentError<1.4994 | ...
  max(s.y(1:end-1),s.y(2:end))+segmentError>1.5606,1,'last');
 if isempty(last), settleUpper=0; else, settleUpper=t(last+1); end
 if ~tail.bound_pass, settleUpper=Inf; end
 % Nonnegative overshoot: a response below its comparison level has zero overshoot.
 osRef=100*max(0,peakUpper-p.r)/p.r; osFinal=100*max(0,peakUpper-s.y(end))/s.y(end);
 sat=abs(s.raw)>5; satDuration=sum(diff(t).*double(sat(1:end-1)));
 intervals=intervals_of(t,sat);
 metric=struct('peak_logged_V',peak,'peak_time_logged_s',t(jpeak),'peak_upper_bound_V',peakUpper, ...
  'overshoot_reference_upper_percent',osRef,'overshoot_final_sample_upper_percent',osFinal, ...
  'rise_10_90_interpolated_s',crossing(t,s.y,.9*p.r)-crossing(t,s.y,.1*p.r), ...
  'settling_time_conservative_upper_s',settleUpper,'final_tracking_error_V',p.r-s.y(end), ...
  'raw_min_V',min(s.raw),'raw_max_V',max(s.raw),'applied_min_V',min(s.applied), ...
  'applied_max_V',max(s.applied),'saturation_left_rectangle_duration_s',satDuration, ...
  'saturation_event_brackets_s',intervals,'I_min_V',min(s.I),'I_max_V',max(s.I), ...
  'AW_max_abs_V_per_s',max(abs(s.aw)),'global_acceleration_bound_V_per_s2',M, ...
  'largest_voltage_interpolation_bound_V',max(segmentError), ...
  'native_I_is_reconstructed',mod(k,2)==0,'last_band_exit_bracket_s',last_exit(t,s.y));
 [~,jr]=max(abs(s.raw)); metric.raw_absolute_peak_time_logged_s=t(jr);
 metric.nominal_tracking_metrics_applicable=strcmp(scenario,'nominal');
 if strcmp(scenario,'stress')
  metric.rise_10_90_interpolated_s=NaN;
  metric.overshoot_reference_upper_percent=NaN;
  metric.overshoot_final_sample_upper_percent=NaN;
  metric.diagnostic_recovery_time_upper_after_return_s=max(0,settleUpper-.2);
 end
 report.(tag).metrics=metric;
 addcheck([tag '_finite_horizon_tracking'],abs(s.y(end)-p.r),1e-6,false);
 if strcmp(scenario,'nominal')
  addcheck([tag '_overshoot_reference'],osRef,2,true);
  addcheck([tag '_overshoot_final_sample'],osFinal,2,true);
  addcheck([tag '_permanent_settling_upper'],settleUpper,.05,true);
 else
  addcheck([tag '_diagnostic_saturation_activated'],double(~any(sat)),0,false);
  addcheck([tag '_diagnostic_AW_activated'],double(max(abs(s.aw))<=1e-3),0,false);
  addcheck([tag '_diagnostic_recovery_rail_clearance'],double(any(sat(t>=.8))),0,false);
  report.(tag).stress_note='Supplemental reference 8 V until 0.2 s then 1.53 V; no formal 0.05 s recovery requirement';
 end
 traces.(tag)=struct('t',t,'signals',s);
end
for pair={'C','D'}
 a=traces.([pair{1} 'E']); b=traces.([pair{1} 'N']); assert(isequal(a.t,b.t),'Matched branches must log common times');
 for n={'y','raw','applied','I','f','aw'}
  delta=max(abs(a.signals.(n{1})-b.signals.(n{1})));
  tol=1e-6; if strcmp(n{1},'aw'), tol=2e-5; end
  addcheck([pair{1} '_native_explicit_' n{1}],delta,tol,false);
 end
end
report.checks=checks; report.all_checks_pass=all([checks.pass]);
report.status='RUN_CHECKS_ONLY_NOT_PROJECT_ACCEPTANCE';
    function addcheck(n,v,limit,strict)
        pass=isfinite(v) && ((strict && v<limit) || (~strict && v<=limit));
        checks(end+1)=struct('name',n,'value',v,'limit',limit,'strict',strict,'pass',pass); %#ok<AGROW>
    end
end
function t0=crossing(t,y,target)
j=find(y>=target,1); if isempty(j), t0=NaN; elseif j==1, t0=t(1);
else, t0=t(j-1)+(target-y(j-1))*(t(j)-t(j-1))/(y(j)-y(j-1)); end
end
function a=intervals_of(t,mask)
starts=find(mask & [true;~mask(1:end-1)]); ends=find(mask & [~mask(2:end);true]); a=zeros(numel(starts),4);
for j=1:numel(starts), a(j,:)=[t(max(1,starts(j)-1)) t(starts(j)) t(ends(j)) t(min(numel(t),ends(j)+1))]; end
end
function b=last_exit(t,y)
inside=y>=1.4994 & y<=1.5606; j=find(inside(1:end-1)&~inside(2:end),1,'last');
if isempty(j), b=[]; else, b=[t(j) t(j+1)]; end
end
