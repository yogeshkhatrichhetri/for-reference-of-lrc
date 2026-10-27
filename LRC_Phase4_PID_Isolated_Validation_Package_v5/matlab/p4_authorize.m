function p4_authorize(owner,stage)
% Pure fail-closed approval predicates. No model/runtime/file mutation.
% Each stage has a separate affirmative flag; construction never grants simulation.
if strcmp(stage,'construction')
    assert(isfield(owner,'construction_authorized') && islogical(owner.construction_authorized) && isscalar(owner.construction_authorized) && owner.construction_authorized, 'Stage A construction/compile authorization required');
elseif strcmp(stage,'simulation')
    assert(isfield(owner,'simulation_authorized') && islogical(owner.simulation_authorized) && isscalar(owner.simulation_authorized) && owner.simulation_authorized, 'Stage B separate simulation authorization required');
    assert(isfield(owner,'proposed_criteria_approved') && islogical(owner.proposed_criteria_approved) && isscalar(owner.proposed_criteria_approved) && owner.proposed_criteria_approved, 'Test criteria require owner approval');
else
    error('Phase4:Stage','Unknown authorization stage');
end
end
