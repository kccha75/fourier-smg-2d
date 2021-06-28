% Gives the Jacobian for the PDE in the form
% (au_xx+bu+cu^2)_xx+du_yy
%
% Jacobian is (ae_xx+(b+2cv)e)_xx+de_yy
%
% Inputs:
% pde.a
% pde.b
% pde.c
% pde.d
% domain.k
%
% Ouputs:
% jacobian.a
% jacobian.b
% jacobian.c

function jacobian=jacobian_Ku_2d(v,pde,domain)

jacobian.a=pde.a;
jacobian.b=pde.b+2*pde.c.*v;
jacobian.c=0;
jacobian.d=pde.d;
jacobian.f=pde.f-fourier_Ku_2d(v,pde,domain);

end