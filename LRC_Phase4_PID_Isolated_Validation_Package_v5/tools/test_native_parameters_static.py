#!/usr/bin/env python3
"""Source-derived metadata/guard regression; no MATLAB or Simulink execution."""
from pathlib import Path
import re,json,math
root=Path(__file__).resolve().parents[1];s=(root/'matlab/phase4_build.m').read_text();checks=[]
def check(name,value):
    assert value,name
    checks.append({'test':name,'pass':True})
req_text=re.search(r'required=\{(.*?)\};',s,re.S).group(1)
required=re.findall(r"'([^']+)'",req_text)
check('required_fields_unique',len(required)==len(set(required)))
for key in ['LimitIntegrator','UpperIntegratorSaturationLimit','LowerIntegratorSaturationLimit','LimitOutput']:
    check('required_'+key,key in required)
check('no_failed_parameter_name_in_builder','LimitIntegratorOutput' not in s)
assertion="assert(all(isfield(dp,required)),'Required native parameters missing; STOP this branch, no substitute');"
check('original_fail_closed_assertion_retained',assertion in s)
config=re.search(r"set_param\(b,'Controller','PID'.*?\);",s,re.S).group(0)
tokens=re.findall(r"'([^']*)'",config);pairs=dict(zip(tokens[::2],tokens[1::2]))
check('native_integrator_limit_off',pairs.get('LimitIntegrator')=='off')
check('native_output_limit_independently_off',pairs.get('LimitOutput')=='off')
check('integrator_limits_not_rewritten','UpperIntegratorSaturationLimit' not in pairs and 'LowerIntegratorSaturationLimit' not in pairs)
check('initial_integrator_limits_read',"upperIntegratorLimit=get_param(b,'UpperIntegratorSaturationLimit');" in s and "lowerIntegratorLimit=get_param(b,'LowerIntegratorSaturationLimit');" in s)
check('infinite_default_validation', 'isequal(str2double(upperIntegratorLimit),Inf) && isequal(str2double(lowerIntegratorLimit),-Inf)' in s)
check('integrator_limit_values_preserved',"isequal(str2double(get_param(b,'UpperIntegratorSaturationLimit')),str2double(upperIntegratorLimit))" in s and "isequal(str2double(get_param(b,'LowerIntegratorSaturationLimit')),str2double(lowerIntegratorLimit))" in s)
for key in ['LimitIntegrator','LimitOutput']:
    check('post_configuration_'+key,"assert(strcmp(get_param(b,'"+key+"'),'off')" in s)
# Evaluate the set-membership semantics of the exact retained isfield/all precondition.
metadata=set(required)
check('complete_synthetic_metadata_passes',all(k in metadata for k in required))
missing=[]
for key in required:
    fixture=metadata-{key}; rejected=not all(k in fixture for k in required)
    assert rejected,key
    missing.append({'missing_field':key,'rejected':True})
check('every_required_field_missing_rejected',len(missing)==len(required))
for name,u,l,expected in [('defaults','inf','-inf',True),('finite_upper','5','-inf',False),('finite_lower','inf','-5',False),('reversed','-inf','inf',False),('malformed','unknown','-inf',False)]:
    try: actual=float(u)==math.inf and float(l)==-math.inf
    except (TypeError,ValueError):actual=False
    check('synthetic_limit_fixture_'+name,actual==expected)
check('construction_gate_explicit',"p4_guard(approval,'construction')" in s)
a=(root/'matlab/p4_authorize.m').read_text().split("if strcmp(stage,'construction')\n",1)[1].split("elseif strcmp(stage,'simulation')",1)[0]
check('construction_independent_of_simulation_permission','construction_authorized' in a and 'simulation_authorized' not in a and 'proposed_criteria_approved' not in a)
code='\n'.join(x for x in s.splitlines() if not x.lstrip().startswith('%'))
check('no_simulation_call_in_construction',not re.search(r'\b(?:sim|phase4_run|phase4_reopen)\s*\(',code))
check('no_simulation_start_command',not re.search(r"'SimulationCommand'\s*,\s*'(?:start|continue|step)'",code))
check('compile_command_retained',"'SimulationCommand','update'" in code)
print(json.dumps({'classification':'STATIC_SOURCE_DERIVED_NOT_MATLAB_RUNTIME','checks':checks,'missing_field_fixtures':missing,'native_parameter_access':'UNVERIFIED','native_construction':'UNVERIFIED'},indent=2))
