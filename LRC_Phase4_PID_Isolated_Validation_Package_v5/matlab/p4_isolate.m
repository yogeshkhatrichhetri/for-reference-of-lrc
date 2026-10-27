function cleanup=p4_isolate(folder)
% Redirect all native working/cache artifacts into this experiment stage.
assert(java.io.File(folder).isAbsolute(),'Use absolute experiment paths');
oldpwd=pwd; oldpath=path; cfg=Simulink.fileGenControl('getConfig');
oldCache=cfg.CacheFolder; oldCode=cfg.CodeGenFolder; oldStructure=cfg.CodeGenFolderStructure;
cleanup=onCleanup(@restore);
cd(folder);
Simulink.fileGenControl('set','CacheFolder',fullfile(folder,'simulation_cache'), ...
 'CodeGenFolder',fullfile(folder,'unused_codegen'),'createDir',true);
    function restore
        Simulink.fileGenControl('set','CacheFolder',oldCache,'CodeGenFolder',oldCode, ...
         'CodeGenFolderStructure',oldStructure);
        cd(oldpwd); path(oldpath);
    end
end
