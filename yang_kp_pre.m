% Function performs Yang's preconditioner for KP
% 
% Preconditioner in the form H=c-(au_xxxx+bu_xx+c)_xx
%
% Inputs:
% v - not used except for size purposes
% pde.a
% pde.b
% pde.f
% domain.dim - can only do 1D or 2D
% domain.discretisation - cheb or fourier
% domain.BC - BC for cheb
% domain.N
% domain.dx
% 
% Ouputs:
% v - solution


function v=yang_kp_pre(~,pde,domain,~)

    c=0.0001;
    [KX,KY]=ndgrid(domain.k{1},domain.k{2});

    v=ifft2(fft2(pde.f)./(c+KX.^6.*pde.a-KX.^4.*pde.b+KX.^2.*pde.c));
    
end