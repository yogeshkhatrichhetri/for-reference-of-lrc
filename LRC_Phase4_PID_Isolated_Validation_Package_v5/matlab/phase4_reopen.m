function phase4_reopen(out,approval)
% Invoke from a NEW MATLAB R2026a process. Loads saved bytes, does not rebuild or save.
p4_guard(approval,'simulation',out);
assert(isempty(find_system('type','block_diagram')),'Fresh MATLAB process required');
phase4_run(out,approval,'nominal','fresh');
phase4_compare(out,approval,'fresh');
end
