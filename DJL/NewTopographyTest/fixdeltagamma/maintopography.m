clear;%close all;%clc

% -------------------------------------------------------------------------
% DJL parameters PICK alpha / mu
% -------------------------------------------------------------------------
% fKdV solution type:
% 0 - 2sech^2 solution
% 1 - fKdV continuation plot!
DJL.soltype=1; 

mode=1; % mode solution
delta_star=1.5;%alpha=0.01; % topography height
gamma_star=0.25;% mu=0.7;
mu=0.90; % topography width scale
KAI=30;KAI=20; % fKdV domain

% N^2 function
N2=@(psi) 1/(exp(1)-1)*exp(psi);%N2=@(psi) 1/(exp(1)-2)*(exp(psi)-1);

% (N^2)'
N2d=@(psi) 1/(exp(1)-1)*exp(psi);%N2d=@(psi) 1/(exp(1)-2)*exp(psi);

DJL.delta_star=delta_star;
DJL.gamma_star=gamma_star;
DJL.mu=mu;
DJL.mode=mode;
DJL.N2=N2;
DJL.N2d=N2d;
DJL.topography=@(X) sech(X).^2; % in KAI domain ...

DJL.KAI=KAI;

% -------------------------------------------------------------------------
time=tic;

% Initialise
[domain,option,cont_option]=DJLinitialise_topography();

% Initial guess
[DJL,fKdV,pdefkdv,domainfkdv,optionfkdv]=DJLv0_topography(DJL,domain,option);
v0=DJL.v;

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

% Interpolate, leave NaN values for extrapolated
v0=interp2(H*(domain.X{2}+1)/2,domain.X{1},v0,YY,XX,'makima',NaN);

% Set BC here ... (but causes huge residual due to discont)
% v0(:,end)=DJL.alpha*DJL.topography(domain.XX(:,end)*KAI/pi); WRONG
v0(:,end)=YY(:,end)/domain.H;

% Interpolate missing data (negative bump generally)
v0(isnan(v0))=griddata(YY(~isnan(v0)),XX(~isnan(v0)),v0(~isnan(v0)),YY(isnan(v0)),XX(isnan(v0)),'cubic');

% Fill missing (extrapolated) data (on boundary generally)
v0=fillmissing(v0,'makima',1); % interpolate boundary wrt rows
v0=fillmissing(v0,'makima',2); % interpolate other stuff wrt columns (if required)
% boundary layer for positive bump (smooths solution)
if DJL.alpha>0

    v0(2:end-1,end-round(0.05*size(domain.x{2})):end-1)=NaN;
    v0(isnan(v0))=griddata(YY(~isnan(v0)),XX(~isnan(v0)),v0(~isnan(v0)),YY(isnan(v0)),XX(isnan(v0)),'cubic');

end

% Initial residual
r=pde.f-(Lu(v0,pde,domain)+N2((domain.X{2}+1)/2-v0).*v0/DJL.u^2);
disp(rms(rms(r)))

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

ds=1e-4;

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
% Newton solve solution 2 positive direction
% -------------------------------------------------------------------------

ds=1e-6;

DJL.u=u1+ds;
[v2,i,flag]=NewtonSolve(v1,DJL,pde,domain,option);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% -------------------------------------------------------------------------
% Continuation DJL positive direction
% -------------------------------------------------------------------------

v=v1;
u=u1;
dv=(v2-v1)/ds;
du=1; % +1 for positive direction, -1 for negative direction

% Continuation
[Vpos,Upos]=pseudocontDJL(v,dv,u,du,DJL,domain,option,cont_option);

dt=toc(time);
fprintf('Elapsed Time is %f s\n',dt)


% -------------------------------------------------------------------------
% PLOTS
% -------------------------------------------------------------------------
U=[fliplr(Uneg) Upos];
V=cat(3,flip(Vneg,3),Vpos);

X2=domain.X{1}/(2*pi)*DJL.Lx;
Y2=(domain.X{2}+1)/2*DJL.Ly/domain.H;

% Calculate momentum
P=trapI(abs(domain.jac).*V.^2,DJL.Lx/domain.N(1)); % Integrate x
P=permute(P,[2,1,3]);
P=clenshaw_curtis(P)/2*DJL.Ly/domain.H; % Integrate y
P=permute(P,[3,1,2]);

% u vs momentum
plot(U,P)
xlabel('u');ylabel('Momentum');title('mode 1 DJL')

% Contour of final solution
figure
contour(X2,Y2,Y2-Vneg(:,:,end),100)
title("Negative C=" + Uneg(end))

figure
contour(X2,Y2,Y2-Vpos(:,:,end),100)
title("Positive C=" + Upos(end))

% Plot(s) of final solution
figure;
plot(X2,Y2-Vneg(:,:,end))
title("Negative C=" + Uneg(end))

% Plot(s) of final solution
figure;
plot(X2,Y2-Vpos(:,:,end))
title("Positive C=" + Upos(end))

% check dv<1 requirement
dv=2*real(ifct(chebdiff(real(fct(transpose(Vneg(:,:,end)))),1)));
max(dv(:))
min(dv(:))
dv=2*real(ifct(chebdiff(real(fct(transpose(Vpos(:,:,end)))),1)));
max(dv(:))
min(dv(:))

fprintf('Domain is %d\n',2*KAI/mu)

% -------------------------------------------------------------------------
% KdV solution 1
% -------------------------------------------------------------------------

B1=fKdV.B;
delta=fKdV.delta;

% -------------------------------------------------------------------------
% KdV solve 2 negative direction
% -------------------------------------------------------------------------

fKdV.delta=delta-ds;

[fKdV,pdefkdv,domainfkdv]=fKdVpdeinitialise(fKdV,domainfkdv); % update parameter

[B2,i,flag]=NewtonSolve(B1,fKdV,pdefkdv,domainfkdv,optionfkdv);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% -------------------------------------------------------------------------
% Continuation fKdV negative direction
% -------------------------------------------------------------------------

B=B1;
D=delta;
dB=(B2-B1)/ds;
dD=-1; % +1 for positive direction, -1 for negative direction

[Bneg,Dneg]=pseudocontdelta(B,dB,D,dD,fKdV,domainfkdv,optionfkdv,cont_option);

% -------------------------------------------------------------------------
% Newton solve solution 2 positive direction
% -------------------------------------------------------------------------

fKdV.delta=delta+ds;

[fKdV,pdefkdv,domainfkdv]=fKdVpdeinitialise(fKdV,domainfkdv); % update parameter

[B2,i,flag]=NewtonSolve(B1,fKdV,pdefkdv,domainfkdv,optionfkdv);

if flag ==0

    fprintf('Initial Newton did not converge ...\n')
    return

end

% -------------------------------------------------------------------------
% Continuation fKdV positive direction
% -------------------------------------------------------------------------

B=B1;
D=delta;
dB=(B2-B1)/ds;
dD=1; % +1 for positive direction, -1 for negative direction

[Bpos,Dpos]=pseudocontdelta(B,dB,D,dD,fKdV,domainfkdv,optionfkdv,cont_option);

% -------------------------------------------------------------------------
% Combine!
% -------------------------------------------------------------------------

D=[fliplr(Dneg) Dpos];
B=cat(2,flip(Bneg,2),Bpos);


% -------------------------------------------------------------------------
% 0th order DJL approx
% -------------------------------------------------------------------------

% Find A
A=6*DJL.s*mu^2/DJL.r*B;

A=reshape(A,[size(A,1),1,size(A,2)]);

% Find zeta from fkdv
zeta0=pagemtimes(A,DJL.phi');

% zeta0 after conformal map
zeta0_map=zeros(size(zeta0));

% Conformal map!
for jj=1:size(zeta0,3)
    
    % Interpolate, leave NaN values for extrapolated
    temp=interp2(H*(domain.X{2}+1)/2,domain.X{1},zeta0(:,:,jj),YY,XX,'makima',NaN);

    % Set BC here ... (but causes huge residual due to discont)
    temp(:,end)=DJL.alpha*DJL.topography(domain.XX(:,end)*KAI/pi);

    % Interpolate missing data (negative bump generally)
    temp(isnan(temp))=griddata(YY(~isnan(temp)),XX(~isnan(temp)),v0(~isnan(temp)),YY(isnan(temp)),XX(isnan(temp)),'cubic');

    % Fill missing (extrapolated) data (on boundary generally)
    temp=fillmissing(temp,'makima',1);
    temp=fillmissing(temp,'makima',2);

    zeta0_map(:,:,jj)=temp;
end
% -------------------------------------------------------------------------
% 1st order DJL approx
% -------------------------------------------------------------------------

% A_xx in x domain (KAI/mu)
A_xx=ifft(-(pi/(1/mu*KAI)*domain.k{1}).^2.*fft(A));

% an
an=pagemtimes(A_xx,DJL.a1)+pagemtimes(A.^2,DJL.a2)+pagemtimes(DJL.alpha*DJL.b,DJL.a3);

% n=N case
an(:,mode,:)=0;

zeta1=pagemtimes(an,DJL.phis');

% Back to zai coordinates
zai=zeta1+DJL.alpha*DJL.b*(1-(domain.x{2}+1)/2)';

zeta=zeta0+zai;

% zeta after conformal map
zeta_map=zeros(size(zeta));

% Conformal map!
for jj=1:size(zeta,3)

    % Interpolate, leave NaN values for extrapolated
    temp=interp2(H*(domain.X{2}+1)/2,domain.X{1},zeta(:,:,jj),YY,XX,'makima',NaN);

    % Set BC here ... (but causes huge residual due to discont)
    temp(:,end)=DJL.alpha*DJL.topography(domain.XX(:,end)*KAI/pi);

    % Interpolate missing data (negative bump generally)
    temp(isnan(temp))=griddata(YY(~isnan(temp)),XX(~isnan(temp)),v0(~isnan(temp)),YY(isnan(temp)),XX(isnan(temp)),'cubic');

    % Fill missing (extrapolated) data (on boundary generally)
    temp=fillmissing(temp,'makima',1);
    temp=fillmissing(temp,'makima',2);

    zeta_map(:,:,jj)=temp;

end

% -------------------------------------------------------------------------
% Plots!
% -------------------------------------------------------------------------

% % Momentum after conformal mapping on physical grid
% Calculate momentum 0th order
P2=trapI(abs(domain.jac).*zeta0_map.^2,DJL.Lx/domain.N(1)); % Integrate x
P2=permute(P2,[2,1,3]);
P2=clenshaw_curtis(P2)/2*DJL.Ly/domain.H; % Integrate y
P2=permute(P2,[3,1,2]);

% Calculate momentum 1st order
P3=trapI(abs(domain.jac).*zeta_map.^2,DJL.Lx/domain.N(1)); % Integrate x
P3=permute(P3,[2,1,3]);
P3=clenshaw_curtis(P3)/2*DJL.Ly/domain.H; % Integrate y
P3=permute(P3,[3,1,2]);

% % Momentum before conformal mapping on x',z' grid (rectangular)
% Calculate momentum 0th order
PP2=trapI(zeta0.^2,DJL.Lx/domain.N(1)); % Integrate x
PP2=permute(PP2,[2,1,3]);
PP2=clenshaw_curtis(PP2)/2; % Integrate y
PP2=permute(PP2,[3,1,2]);

% Calculate momentum 1st order
PP3=trapI(zeta.^2,DJL.Lx/domain.N(1)); % Integrate x
PP3=permute(PP3,[2,1,3]);
PP3=clenshaw_curtis(PP3)/2; % Integrate y
PP3=permute(PP3,[3,1,2]);

% Compare all 
figure;
plot(DJL.C+D*DJL.s*mu^2,P2,DJL.C+D*DJL.s*mu^2,P3,U,P)
xlabel('delta');ylabel('Momentum');title('DJL momentums')
legend('0th order fKdV approx of DJL','1st order fKdV approx of DJL','Exact DJL')