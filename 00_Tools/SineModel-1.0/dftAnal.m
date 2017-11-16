function [ X, mX, pX ] = dftAnal( x, N, window )
%%
%	Analysis of a signal using the discrete Fourier transform
%            x: input signal,
%            N: DFT size (no constraint on power 2!),
%       window: analysis window (in term of vector)
%	returns X, mX, pX: complex, magnitude and phase spectrum

% window the input sound
xw = x.*window;

% zero-phase window in fftbuffer
M = numel(window);                     % window Size
hM1 = floor((M+1)/2);                   % half analysis window size by floor
hM2 = floor(M/2);                       % half analysis window size by floor
fftbuffer = zeros(N, 1);                % initialize buffer for FFT
if mod(hM2,2) == 1
    fftbuffer(1:hM2) = xw(hM1+1:end);
    fftbuffer(end-hM1+1:end) = xw(1:hM1);    
else
    fftbuffer(1:hM1) = xw(hM2+1:end);
    fftbuffer(end-hM2+1:end) = xw(1:hM2);
end

% Compute FFT
hN = floor(N/2)+1;                      % size of positive spectrum, it includes sample 0
X = fft(fftbuffer); 
X = X(1:hN);
% compute absolute value of positive side
mX = abs(X);

% for phase calculation set to 0 the small values
% Equivalence Python Code
% X[:hN].real[np.abs(X[:hN].real) < tol] = 0.0
% X[:hN].imag[np.abs(X[:hN].imag) < tol] = 0.0
X(abs(real(X(1:hN)))<1e-14) = 1i * imag( X(abs(real(X(1:hN)))<1e-14) );
X(abs(imag(X(1:hN)))<1e-14) = real( X(abs(imag(X(1:hN)))<1e-14) );
% unwrapped phase spectrum of positive frequencies
pX = unwrap(angle(X(1:hN)));

end
