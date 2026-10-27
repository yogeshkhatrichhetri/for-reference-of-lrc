#!/usr/bin/env python3
"""Source-derived approval predicate tests. Does NOT run MATLAB/Simulink."""
from pathlib import Path
import json,re
root=Path(__file__).resolve().parents[1]
s=(root/'matlab/p4_authorize.m').read_text()
parts=s.split("if strcmp(stage,'construction')\n",1)[1].split("elseif strcmp(stage,'simulation')\n")
branches={'construction':parts[0], 'simulation':parts[1].split('\nelse\n')[0]}
pattern=re.compile(r"\s*assert\(isfield\(owner,'(\w+)'\) && islogical\(owner\.(\w+)\) && isscalar\(owner\.(\w+)\) && owner\.(\w+), '[^']+'\);\s*")
fields={}
for stage,body in branches.items():
    fields[stage]=[]
    for line in body.splitlines():
        if not line.strip():continue
        m=pattern.fullmatch(line)
        assert m and len(set(m.groups()))==1, 'Unrecognized predicate: do not silently model different code'
        fields[stage].append(m[1])
assert fields=={'construction':['construction_authorized'],'simulation':['simulation_authorized','proposed_criteria_approved']}
def permits(stage,owner):
    return all(type(owner.get(f)) is bool and owner[f] for f in fields[stage])
cases=[
 ('A_absent','construction',{},False),
 ('A_false','construction',{'construction_authorized':False},False),
 ('A_string_not_permission','construction',{'construction_authorized':'true'},False),
 ('A_numeric_not_permission','construction',{'construction_authorized':1},False),
 ('A_true_B_false_criteria_false','construction',{'construction_authorized':True,'simulation_authorized':False,'proposed_criteria_approved':False},True),
 ('B_absent_even_when_A_true','simulation',{'construction_authorized':True,'proposed_criteria_approved':True},False),
 ('B_false_even_when_A_true','simulation',{'construction_authorized':True,'simulation_authorized':False,'proposed_criteria_approved':True},False),
 ('B_false_A_false','simulation',{'construction_authorized':False,'simulation_authorized':False,'proposed_criteria_approved':True},False),
 ('B_true_criteria_false','simulation',{'simulation_authorized':True,'proposed_criteria_approved':False},False),
 ('B_true_criteria_missing','simulation',{'simulation_authorized':True},False),
 ('B_string_not_permission','simulation',{'simulation_authorized':'true','proposed_criteria_approved':True},False),
 ('B_positive_predicates_only','simulation',{'construction_authorized':False,'simulation_authorized':True,'proposed_criteria_approved':True},True),
]
rows=[]
for name,stage,owner,expected in cases:
    actual=permits(stage,owner);assert actual==expected,name
    rows.append({'test':name,'expected_allowed':expected,'predicate_allowed':actual,'pass':True})
# Extract the exact stress predicate from the actual runner, not a separate policy copy.
runner=(root/'matlab/phase4_run.m').read_text()
stress_body=runner.split("if strcmp(scenario,'stress')\n",1)[1].split('\nend',1)[0]
stress_line=stress_body.splitlines()[0]
stress_pattern=re.compile(r"\s*assert\(isfield\(owner,'(\w+)'\) && islogical\(owner\.(\w+)\) && isscalar\(owner\.(\w+)\) && isequal\(owner\.(\w+),true\),'[^']+'\);\s*")
m=stress_pattern.fullmatch(stress_line)
assert m and len(set(m.groups()))==1 and m[1]=='supplemental_stress_approved'
# Inspect executable source ordering (not native execution). Preserve all Boolean cases below.
code='\n'.join(x for x in runner.splitlines() if not x.lstrip().startswith('%'))
guard_position=code.index(stress_line)
ordering=[]
for name,token in [
 ('guard_before_run_directory_creation','mkdir(rundir)'),
 ('guard_before_isolation','p4_isolate(rundir)'),
 ('guard_before_model_loading','load_system(modelFile)'),
 ('guard_before_diary',"diary(fullfile(rundir,'execution_diary.txt'))"),
 ('guard_before_stress_configuration','in=in.setBlockParameter('),
 ('guard_before_simulation','result=sim(in)')]:
    assert guard_position<code.index(token),name
    ordering.append({'test':name,'pass':True})
validation="if strcmp(precision,'fresh'), assert(strcmp(scenario,'nominal'),'Fresh check uses nominal'); end\n"
expected=validation+"if strcmp(scenario,'stress')\n"+stress_line+"\nend\nrundir="
assert expected in code, 'Stress guard must immediately follow scenario/precision validation'
assert code.count(stress_line)==1, 'Guard must not remain at the late location'
ordering.append({'test':'guard_immediately_after_scenario_precision_validation','pass':True})
def stress_permits(scenario,owner):
    # Models only the extracted approval predicate, not runtime identity/solver behavior.
    return scenario!='stress' or (type(owner.get(m[1])) is bool and owner[m[1]] is True)
stress_cases=[
 ('stress_missing',{},False),
 ('stress_logical_false',{'supplemental_stress_approved':False},False),
 ('stress_logical_true_predicate_only',{'supplemental_stress_approved':True},True),
 ('stress_string_true',{'supplemental_stress_approved':'true'},False),
 ('stress_numeric_one',{'supplemental_stress_approved':1},False),
 ('stress_nonscalar_logical_array',{'supplemental_stress_approved':[True,True]},False),
 ('stress_empty_array',{'supplemental_stress_approved':[]},False),
 ('stress_null',{'supplemental_stress_approved':None},False),
 ('stress_object',{'supplemental_stress_approved':{}},False),
]
for name,owner,expected in stress_cases:
    actual=stress_permits('stress',owner); assert actual==expected,name
    rows.append({'test':name,'expected_allowed':expected,'predicate_allowed':actual,'pass':True})
nominal_owner={'simulation_authorized':True,'proposed_criteria_approved':True,'supplemental_stress_approved':False}
assert permits('simulation',nominal_owner) and stress_permits('nominal',nominal_owner)
rows.append({'test':'nominal_StageB_predicates_true_stress_false','expected_allowed':True,'predicate_allowed':True,'pass':True})
template=json.loads((root/'OWNER_REVIEW_TEMPLATE.json').read_text())
assert template['supplemental_stress_approved'] is False
# Actual file/model identities remain required after positive Boolean predicates.
for name,stage in [('phase4_build','construction'),('phase4_run','simulation'),('phase4_reopen','simulation'),('phase4_compare','simulation')]:
    text=(root/f'matlab/{name}.m').read_text()
    assert f"p4_guard(approval,'{stage}'" in text
    gate=text.index(f"p4_guard(approval,'{stage}'")
    for operation in ['load_system(', 'new_system(', 'sim(', 'phase4_run(']:
        # Exclude the function declaration itself, and comments.
        body='\n'.join(x for x in text.splitlines()[1:] if not x.lstrip().startswith('%'))
        if operation in body: assert body.index('p4_guard(')<body.index(operation)
    if stage=='construction':
        assert not re.search(r'(?m)^\s*(?:\w+\s*=\s*)?(?:sim|phase4_run|phase4_reopen)\(',body)
        assert not re.search(r'simulation_authorized\s*=',body)
g=(root/'matlab/p4_guard.m').read_text()
for binding in ['owner.package_manifest_sha256','owner.source_sha256','owner.test_register_sha256','owner.build_record_sha256','owner.constructed_model_sha256','p4_hash(modelFile)','build.package_manifest_sha256','build.test_register_sha256']:
    assert binding in g,binding
assert g.index('p4_authorize(owner,stage)')<g.index("version('-release')")
# Overshoot arithmetic fixture checks, not plant or controller simulation.
a=(root/'matlab/p4_assess.m').read_text()
assert 'osRef=100*max(0,peakUpper-p.r)/p.r;' in a
assert 'osFinal=100*max(0,peakUpper-s.y(end))/s.y(end);' in a
for level in [1.53,1.529]:
    for peak in [level-.1,level,level+.01]:
        value=100*max(0,peak-level)/level
        assert value>=0
        if peak<=level: assert value==0
assert "osRef,2,true" in a and "osFinal,2,true" in a
print(json.dumps({'classification':'STATIC_SOURCE_DERIVED_PREDICATE_HARNESS_NOT_MATLAB_EXECUTION','cases':rows,'ordering_tests':ordering,'entrypoint_guard_checks':'PASS','identity_binding_source_checks':'PASS','overshoot_synthetic_arithmetic':'PASS','native_guard_execution':'UNVERIFIED'},indent=2))
