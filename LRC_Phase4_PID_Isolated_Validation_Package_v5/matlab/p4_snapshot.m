function s=p4_snapshot(m)
s=struct; s.constants=p4_constants;
names={'Solver','SolverType','MaxStep','RelTol','AbsTol','StartTime','StopTime','SaveState', ...
 'StateSaveName','SaveFormat','LimitDataPoints','ReturnWorkspaceOutputs','SimulationMode'};
for k=1:numel(names), s.configuration.(names{k})=get_param(m,names{k}); end
mw=get_param(m,'ModelWorkspace'); pp=p4_constants;
for n=fieldnames(pp)', assert(isequal(getVariable(mw,n{1}),pp.(n{1})),'Altered model constant %s',n{1}); end
blocks=sort(find_system(m,'LookUnderMasks','none','FollowLinks','off','Type','Block'));
s.blocks=cell(numel(blocks),1);
for k=1:numel(blocks)
 b=blocks{k}; r=struct('path',erase(b,[m '/']),'type',get_param(b,'BlockType'));
 dp=get_param(b,'DialogParameters'); r.parameters=struct;
 if ~isempty(dp)
  keys=sort(fieldnames(dp));
  for j=1:numel(keys), r.parameters.(keys{j})=get_param(b,keys{j}); end
 end
 pc=get_param(b,'PortConnectivity'); r.connections=cell(numel(pc),1);
 for j=1:numel(pc)
  c=struct('type',pc(j).Type,'src_port',pc(j).SrcPort,'dst_port',pc(j).DstPort);
  c.src=paths(pc(j).SrcBlock,m); c.dst=paths(pc(j).DstBlock,m); r.connections{j}=c;
 end
 s.blocks{k}=r;
end
end
function a=paths(h,m)
a=cell(size(h));
for k=1:numel(h)
 if h(k)<0, a{k}='UNCONNECTED'; else, a{k}=erase(getfullname(h(k)),[m '/']); end
end
end
