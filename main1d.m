clear;close all;%clc
% -------------------------------------------------------------------------
% Solve PDE -u_xx + au_x + bu = f using Fourier Spectral Multigrid at
% Fourier collocation points
%
% -------------------------------------------------------------------------
% INPUT PARAMETERS
% -------------------------------------------------------------------------
L(1) = 2 * pi;
finestgrid = 7;
coarsestgrid = 3;

% PDE Parameters

a=@(x) 23+sin(x).*cos(x);%+epsilon*exp(cos(X+Y));
b=@(x) 1+exp(cos(x));%+epsilon*exp(cos(X+Y));

f=@(x) -2*cos(x).^2+(3+exp(cos(x))).*sin(x).^2+sin(2*x);

% Exact solution
ue=@(x) sin(x).^2;

% Initial guess
Nx=2^finestgrid;
v0=@(x) 0*x;

% -------------------------------------------------------------------------
% Multigrid Options here
% -------------------------------------------------------------------------

% Number of V-cycles if option is chosen, otherwise number of v-cycles done
% after FMG
option.num_vcycles=10;

% Solver / solution tolerance
option.tol=1e-12;

% Relaxations on the up and down cycle during Multigrid
option.Nd=1;
option.Nu=1;

% Multigrid solver options:'V-cycle' or 'FMG'
option.solver='V-cycle';

% Multigrid scheme: 'Correction' or 'FAS'
option.mgscheme='Correction';

% Operator, coarse grid solver, Relaxation, Restriction, Prolongation options
option.operator=@fourier_Lu_1d;
option.coarsegridsolver=@fourier_matrixsolve_1d;
option.relaxation=@MRR;
option.restriction=@fourier_restrict_filtered;
option.prolongation=@fourier_prolong_filtered;

% Preconditioner
option.preconditioner=@fourier_FD_1d;
% Number of precondition relaxations
option.prenumit=1;

% -------------------------------------------------------------------------
% Set up parameters
% -------------------------------------------------------------------------
N(1) = 2^finestgrid;
N(2) = 1;

% Spectral Wave numbers
k(:,1) = 2*pi/L(1)*[0:N(1)/2-1 -N(1)/2 -N(1)/2+1:-1]';

x(:,1) = L(1)*(-N(1)/2:N(1)/2-1)'/N(1);

a=a(x);
b=b(x);
f=f(x);

ue=ue(x);
v0=v0(x);

% -------------------------------------------------------------------------
% Sort into structures
% -------------------------------------------------------------------------
% Assuming constant dx
dx(1) = x(2,1)-x(1,1);

% Sort into structures
domain.L = L;
domain.N = N;
domain.k = k;
domain.dx = dx;

pde.a = a;
pde.b = b;
pde.f = f;

option.finestgrid=finestgrid;
option.coarsestgrid=coarsestgrid;
option.grids=finestgrid-coarsestgrid+1;

% -------------------------------------------------------------------------
% Solve
% -------------------------------------------------------------------------
% MG here

tic
[v,r]=mg(v0,pde,domain,option);

% Check if Poisson type problem, then scale for mean 0 solution
if max(abs(pde.b(:)))<1e-12
    v=v-1/(Nx(1)*N(2))*sum(sum(v));
end

toc

vv=cg(v0,pde,domain,option);