function phase4_compare(out,approval,mode)
% Postprocess existing evidence only; never invokes sim or changes model.
[~,owner]=p4_guard(approval,'simulation',out); assert(any(strcmp(mode,{'convergence','fresh'})));
file=fullfile(out,[mode '_comparison.json']); assert(~isfile(file),'Comparison already exists');
rows=struct([]);
if strcmp(mode,'convergence'), scenarios={'nominal','stress'}; else, scenarios={'nominal'}; end
for sc=scenarios
 if strcmp(mode,'convergence'), aa=[sc{1} '_base']; bb=[sc{1} '_refined'];
 else, aa=[sc{1} '_refined']; bb=[sc{1} '_fresh']; end
 a=load(fullfile(out,aa,'raw_timeseries.mat'),'raw'); b=load(fullfile(out,bb,'raw_timeseries.mat'),'raw');
 ar=jsondecode(fileread(fullfile(out,aa,'assessment.json'))); br=jsondecode(fileread(fullfile(out,bb,'assessment.json')));
 for tag={'CE','CN','DE','DN'}
  for signal={'y','raw','applied'}
   key=[tag{1} '_' signal{1}]; sa=a.raw.(key); sb=b.raw.(key);
   [ta,ia]=unique(sa.Time(:),'last'); va=sa.Data(:); va=va(ia);
   [tb,ib]=unique(sb.Time(:),'last'); vb=sb.Data(:); vb=vb(ib);
   if strcmp(mode,'fresh')
    assert(isequal(ta,tb),'Fresh process changed time grid; no silent interpolation');
    delta=max(abs(va-vb)); limit=1e-9;
   else
    % Compare refined values at base timestamps, keeping ZOH controls right-continuous.
    method='linear'; if startsWith(tag{1},'D') && ~strcmp(signal{1},'y'), method='previous'; end
    delta=max(abs(va-interp1(tb,vb,ta,method)));
    limit=1e-4; if strcmp(signal{1},'y'), limit=1e-7; end
   end
   add([sc{1} '_' key],delta,limit);
  end
  if strcmp(mode,'convergence') && strcmp(sc{1},'nominal')
   am=ar.(tag{1}).metrics; bm=br.(tag{1}).metrics;
   add([tag{1} '_peak_convergence'],abs(am.peak_upper_bound_V-bm.peak_upper_bound_V),1e-7);
   % Conservative settling upper bounds include logging gap; 3 us allows expected 2 vs 1 us bracketing.
   add([tag{1} '_settling_convergence'],abs(am.settling_time_conservative_upper_s-bm.settling_time_conservative_upper_s),3e-6);
   add([tag{1} '_strict_deadline_with_convergence_uncertainty'], ...
    bm.settling_time_conservative_upper_s+abs(am.settling_time_conservative_upper_s-bm.settling_time_conservative_upper_s),.05-eps(.05));
   add([tag{1} '_strict_peak_with_convergence_uncertainty'], ...
    bm.peak_upper_bound_V+abs(am.peak_upper_bound_V-bm.peak_upper_bound_V),1.5606-eps(1.5606));
  end
 end
 add([sc{1} '_both_run_checks_pass'],double(~(ar.all_checks_pass && br.all_checks_pass)),0);
end
r=struct('owner',owner,'approval_record_sha256',p4_hash(approval),'mode',mode,'checks',rows,'all_checks_pass',all([rows.pass]), ...
 'status','SUBTASK_NUMERICAL_COMPARISON_ONLY_NOT_OVERALL_ACCEPTANCE');
p4_json(file,r); assert(r.all_checks_pass,'Comparison failed; preserve evidence and stop');
    function add(n,v,l)
        rows(end+1)=struct('name',n,'value',v,'limit',l,'pass',isfinite(v)&&v<=l); %#ok<AGROW>
    end
end
