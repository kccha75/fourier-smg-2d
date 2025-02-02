clear;%close all;%clc

% -------------------------------------------------------------------------
% DJL parameters
% -------------------------------------------------------------------------

% alpha=0.05;
% epsilon=sqrt(alpha);
epsilon=0.4;
% mu=alpha^(1/4);
% converges on e=1 (bit weird),e=0.02 (weird solution), e=0.3
mode=1;

% N^2 function
N2=@(psi) sech((psi-0.6)/1).^2;N2=@(psi) psi;

% (N^2)'
N2d=@(psi) -2*sech((psi-0.6)/1).^2.*tanh((psi-0.6)/1);N2d=@(psi) 1+0*psi;

DJL.epsilon = epsilon;
% DJL.alpha = alpha;
% DJL.mu = mu;

DJL.mode=mode;

DJL.N2=N2;
DJL.N2d=N2d;

DJL.topography=@(X) sech(X).^2; % in KAI domain ...

% -------------------------------------------------------------------------
time=tic;

% Initialise
[domain,option,cont_option]=DJLinitialise_topography();

% Initial guess
[v0,DJL]=DJLv0_topography_test3(DJL,domain);

% Conformal mapping and interpolation
[mapping,DJL]=conformalmapping(DJL,domain,option);


KAI=DJL.KAI;
mu=DJL.mu;
Lx=DJL.Lx;
Ly=DJL.Ly;

XX=mapping.XX;
YY=mapping.YY;
jac=mapping.jac;
H=mapping.H;

% Initialise PDE
[pde,domain]=DJLpdeinitialise_topography(DJL,mapping,domain);

v0=interp2(H*(domain.X{2}+1)/2,domain.X{1},v0,YY,XX,'spline');

% initial residual ..?
r=pde.f-(Lu_2d(v0,pde,domain)+N2((domain.X{2}+1)/2-v0).*v0/DJL.u^2);
disp(rms(rms(r)))

% Newton solve
[v,i,flag]=NewtonSolve(v0,DJL,pde,domain,option);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% Continuation
% [V,U]=naturalparametercontinuation(v,DJL.u,DJL,domain,cont_option);

dt=toc(time);
fprintf('Elapsed Time is %f s\n',dt)
% -------------------------------------------------------------------------
% PLOTS
% -------------------------------------------------------------------------
KAI=DJL.KAI;

X2=domain.X{1}/pi*KAI/mu^2;
Y2=(domain.X{2}+1)/2;

% Calculate momentum
P=trapI(V.^2,domain.dx{1}); % Integrate x
P=permute(P,[2,1,3]);
P=clenshaw_curtis(2*P/pi*KAI/mu^2); % Integrate y
P=permute(P,[3,1,2]);

% u vs momentum
plot(U,P)
xlabel('u');ylabel('Momentum');title('mode 1 DJL')

% Contour of final solution
figure
contour(X2,Y2,Y2-V(:,:,end),100)
title("C=" + U(end))

% Plot(s) of final solution
figure;
plot(X2,Y2-V(:,:,end))
title("C=" + U(end))

% check dv<1 requirement
dv=2*ifct(chebdiff(fct(V(:,:,end)'),1));
max(dv(:))
min(dv(:))

fprintf('Domain is %d\n',KAI/mu^2)