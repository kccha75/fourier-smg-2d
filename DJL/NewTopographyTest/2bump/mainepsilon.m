% Continuation uses mu09 results, continuation in epsilon

% load data here! 
clear; 
load('gammastar05/exp/U.mat') % initial alpha
alpha=U(1);

load('gammastar05/exp/V.mat') % solution
load('gammastar05/exp/W.mat') % alpha

% -------------------------------------------------------------------------
% DJL parameters PICK alpha / mu
% -------------------------------------------------------------------------
% fKdV solution type:
% 0 - 2sech^2 solution
% 1 - fKdV continuation plot!
DJL.soltype=3; 

mu=0.7; % topography width scale
KAI=25; % fKdV domain, since L=200

% N^2 function
epsilon=-1;
N2=@(psi) exp(epsilon*psi)/((exp(epsilon)-1)/epsilon);

% (N^2)'
N2d=@(psi) epsilon*exp(epsilon*psi)/((exp(epsilon)-1)/epsilon);

DJL.mu=mu;
DJL.N2=N2;
DJL.N2d=N2d;
DJL.topography=@(X) sech(X+12).^2+sech(X-12).^2; % in KAI domain ...
DJL.alpha=alpha; % continuation point!
DJL.KAI=KAI;
DJL.Lx=2*KAI/mu^2;
% -------------------------------------------------------------------------
time=tic;

% Initialise
[domain,option,cont_option]=DJLinitialise_topography();

% Conformal mapping and interpolation
[DJL,domain]=conformalmapping(DJL,domain,option);

% Length scales in DJL coordinates
Lx=DJL.Lx;
Ly=DJL.Ly;

XX=domain.XX;
YY=domain.YY;
jac=domain.jac;
H=domain.H;

% Initialise PDE
[DJL,pde,domain]=DJLpdeinitialise_topography(DJL,domain);

v=V(:,:,1); % continuation point!
u=W(1); % continuation point!
DJL.u=u;
% -------------------------------------------------------------------------
% Newton solve solution 1
% -------------------------------------------------------------------------

u1=DJL.u;
[v1,i,flag]=NewtonSolve(v,DJL,pde,domain,option);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% -------------------------------------------------------------------------
% Newton solve solution 2 negative direction
% -------------------------------------------------------------------------

ds=1e-5;

DJL.u=u1-ds;u2=u1-ds;
[v2,i,flag]=NewtonSolve(v1,DJL,pde,domain,option);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% -------------------------------------------------------------------------
% Find Tabletop solution using Secant method
% -------------------------------------------------------------------------

[v,u,y,i,secantflag]=DJLtabletopsecant(v1,v2,u1,u2,DJL,pde,domain,option);

cont_option.ds=cont_option.ds;

% continuation
if secantflag==1
    [V,U,W]=naturalparametercontalphaDJLepsilon(v,u,epsilon,DJL,domain,option,cont_option);
end
