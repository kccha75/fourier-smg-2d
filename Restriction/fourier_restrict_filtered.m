% Fourier Restriction operator on x direction (first component)
% assuming fine grid is 2x coarse grid points in x
%
% Assumed filtered for highest mode
%
% Inputs:
% vf - fine grid (Nx * Ny * ... size)
%
% Outputs:
% vc - coarse grid (Nx/2 * Ny * ... size)

function vc=fourier_restrict_filtered(vf)

N=size(vf);

% FFT + shift
v_hat=fftshift(fft(vf),1);

% Filter high frequency
v_hat=v_hat(N(1)/4+1:3*N(1)/4,:);

% shift + iFFT
vc=0.5*real(ifft(fftshift(v_hat,1)));

% Reshape to correct size (required for 3d or higher)
N(1)=N(1)/2;
vc=reshape(vc,N);

end