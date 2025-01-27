clear;close all;%clc

% -------------------------------------------------------------------------
% DJL parameters
% -------------------------------------------------------------------------

epsilon=1;
alpha=epsilon^2;
mu=sqrt(epsilon);
u=0.285; % CHECK WITH v0 TO MAKE SURE
mode=1;

% N^2 function
N2=@(psi) sech(psi-1).^2;

% (N^2)'
N2d=@(psi) -2*sech(psi-1).^2.*tanh(psi-1);

DJL.epsilon = epsilon;
DJL.alpha = alpha;
DJL.mu = mu;
DJL.u = u;
DJL.mode=mode;

DJL.N2=N2;
DJL.N2d=N2d;

DJL.topography=@(X) sech(X).^2; % in KAI domain ...

% -------------------------------------------------------------------------
time=tic;

% Initialise
[domain,option,cont_option]=DJLinitialise();

% Initial guess
[v0,DJL]=DJLv0(DJL,domain);

% Initialise PDE
[pde,domain]=DJLpdeinitialise(DJL,domain);

disp(rms(rms(pde.f-(Lu(v0,pde,domain)+N2((domain.X{2}+1)/2-v0).*v0/DJL.u^2))))

% -------------------------------------------------------------------------
% Newton solve solution 1
% -------------------------------------------------------------------------

u1=DJL.u;
[v1,i,flag]=NewtonSolve(v0,DJL,pde,domain,option);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% -------------------------------------------------------------------------
% Newton solve solution 2 negative direction
% -------------------------------------------------------------------------

ds=cont_option.ds;

DJL.u=u1-ds;
[v2,i,flag]=NewtonSolve(v1,DJL,pde,domain,option);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% -------------------------------------------------------------------------
% Continuation DJL negative direction
% -------------------------------------------------------------------------

v=v1;
u=u1;
dv=(v2-v1)/ds;
du=-1; % +1 for positive direction, -1 for negative direction

% Continuation
[Vneg,Uneg]=pseudocontDJL(v,dv,u,du,DJL,domain,option,cont_option);

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