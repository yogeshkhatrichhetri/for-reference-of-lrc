function p=p4_constants
% Frozen source decimal literals. No tuning or base-workspace dependencies.
p=struct('Kp',2.050062959107108,'Ki',40.633656994693226, ...
 'Kd',0.027442375755061164,'N',49999.55245385603,'Ts',0.01, ...
 'Kaw',20,'umin',-5,'umax',5,'r',1.53,'R',10,'Req',40,'L',1,'C',510e-6);
p.alpha=1/(1+p.N*p.Ts); p.beta=p.Kd*p.N*p.alpha;
end
