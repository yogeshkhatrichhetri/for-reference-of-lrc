function b=p4_tail(x,discrete)
% Conditional future-tail bound for the declared, unsaturated equations.
% Reconstructed native controller state is explicitly not a directly logged internal state.
p=p4_constants; A=[-(p.R+p.Req)/p.L -1/p.L;1/p.C 0]; B=[1/p.L;0];
if discrete
 E=expm([A B;zeros(1,3)]*p.Ts); Ad=E(1:2,1:2); Bd=E(1:2,3);
 U=[0 -p.Kp-p.beta 1 p.beta];
 F=[Ad zeros(2,2)]+Bd*U;
 F=[F;0 -p.Ts*p.Ki 1 0;0 1-p.alpha 0 p.alpha];
 [V,D]=eig(F); poles=diag(D); stable=all(abs(poles)<1);
else
 U=[0 -p.Kp-p.Kd*p.N 1 p.Kd*p.N];
 F=[A zeros(2,2)]+B*U;
 F=[F;0 -p.Ki 0 0;0 p.N 0 -p.N];
 [V,D]=eig(F); poles=diag(D); stable=all(real(poles)<0);
end
z=V\(x-[0;p.r;p.r;p.r]);
if discrete
 [Vp,Dp]=eig(A); assert(all(real(diag(Dp))<0));
 w=zeros(1,4);
 for j=1:4
  q=U*V(:,j); v=V(1:2,j)-[0;1]*q;
  w(j)=sum(abs(([0 1]*Vp).*(Vp\v).'))+abs(q);
 end
 ybound=sum(w.*abs(z.'));
else
 ybound=sum(abs(V(2,:).*z.'));
end
ubound=sum(abs((U*V).*z.'));
% Roundoff allowance is a proposed diagnostic numerical safety factor, not interval arithmetic.
ybound=10*ybound+1e-9; ubound=10*ubound+1e-9;
b=struct('stable',stable,'poles_real',real(poles),'poles_imag',imag(poles), ...
 'spectral_radius',max(abs(poles)),'eigenvector_condition',cond(V), ...
 'future_output_error_bound_V',ybound,'future_control_error_bound_V',ubound, ...
 'bound_pass',stable && ybound<0.0306 && ubound<min(p.umax-p.r,p.r-p.umin) && cond(V)<1e10, ...
 'classification','DERIVED_CONDITIONAL_BOUND_FROM_TERMINAL_NATIVE_OR_RECONSTRUCTED_STATE_NOT_INFINITE_NATIVE_EXECUTION');
end
