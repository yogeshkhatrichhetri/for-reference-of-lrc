function [pkg,owner]=p4_guard(approval,stage,out)
pkg=fileparts(fileparts(mfilename('fullpath')));
assert(isfile(approval),'Owner approval record required');
owner=jsondecode(fileread(approval));
p4_authorize(owner,stage); % Gate checked before querying or loading native software.
assert(strlength(string(owner.owner))>0 && strlength(string(owner.utc))>0,'Owner/date missing');
assert(strcmp(version('-release'),'2026a'),'This package targets MATLAB R2026a.');
v=ver('simulink'); assert(~isempty(v) && startsWith(v.Version,'26.1'),'Simulink 26.1 required.');
assert(license('test','Simulink'),'Simulink license unavailable.');
manifest=splitlines(string(fileread(fullfile(pkg,'SHA256SUMS.txt'))));
for k=1:numel(manifest)
 if strlength(manifest(k))==0, continue; end
 line=char(manifest(k)); assert(numel(line)>66 && strcmp(line(65:66),'  '),'Malformed manifest');
 rel=line(67:end); assert(~contains(rel,'..') && ~startsWith(rel,'/'),'Unsafe manifest path');
 assert(strcmp(p4_hash(fullfile(pkg,rel)),line(1:64)),'Package checksum mismatch: %s',rel);
end
source=fullfile(pkg,'baseline','LRC_Phase2_OpenLoop.slx');
assert(strcmp(p4_hash(source),'3833d3951b4c33ec265f54b8e91c4b4c4a65474fee357e8186fccc19ca992fd1'),'Source model identity mismatch');
assert(strcmp(owner.package_manifest_sha256,p4_hash(fullfile(pkg,'SHA256SUMS.txt'))),'Wrong approved package manifest');
assert(strcmp(owner.source_sha256,p4_hash(source)),'Wrong approved source identity');
assert(strcmp(owner.test_register_sha256,p4_hash(fullfile(pkg,'TEST_REGISTER.md'))),'Wrong approved test register');
if strcmp(stage,'simulation')
    assert(nargin==3 && isfolder(out),'Established construction directory required');
    record=fullfile(out,'build_record.json');
    assert(strcmp(owner.build_record_sha256,p4_hash(record)),'Wrong approved construction record');
    build=jsondecode(fileread(record));
    assert(strcmp(build.model,'LRC_Phase4_PID_Isolated'),'Wrong constructed model name');
    assert(strcmp(build.package_manifest_sha256,owner.package_manifest_sha256),'Construction used a different package');
    assert(strcmp(build.test_register_sha256,owner.test_register_sha256),'Construction used a different test register');
    assert(strcmp(build.source_sha256,owner.source_sha256),'Construction used a different source');
    p4_authorize(build.owner,'construction');
    assert(strcmp(build.status,'CONSTRUCTED_AND_COMPILED_ONLY_NOT_SIMULATED'),'Construction not established');
    modelFile=fullfile(out,[build.model '.slx']);
    assert(strcmp(owner.constructed_model_sha256,build.model_sha256) && strcmp(p4_hash(modelFile),build.model_sha256),'Wrong approved constructed-model hash');
end
end
