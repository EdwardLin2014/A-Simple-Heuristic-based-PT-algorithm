function [ y ] = dftSynth( mX, pX, M, N )
%%
%   Synthesis of a signal using the discrete Fourier transform
%       mX: magnitude spectrum, 
%       pX: phase spectrum, 
%        M: window size,
%        N: DFT size (no constraint on power 2!)
%	returns y: output signal

hN = numel(mX);                                        % size of positive spectrum, it includes sample 0
hM1 = floor((M+1)/2);                                   % half analysis window size by rounding
hM2 = floor(M/2);                                       % half analysis window size by floor
y = zeros(M,1);                                         % initialize output array
Y = complex(zeros(N,1),0);                              % clean output spectrum

Y(1:hN) = mX .* exp(1j.*pX);
if mod(hN,2) == 1
    Y(hN+1:end) = mX(end-1:-1:2) .* exp(-1j.*pX(end-1:-1:2));
else
    Y(hN+1:end) = mX(end:-1:2) .* exp(-1j.*pX(end:-1:2));
end

fftbuffer = real(ifft(Y));                            % compute inverse FFT
if mod(hM2,2) == 1
    y(1:hM1) = fftbuffer(end-hM1+1:end);                  % undo zero-phase window
    y(hM1+1:end) = fftbuffer(1:hM2);
else
    y(1:hM2) = fftbuffer(end-hM2+1:end);                  % undo zero-phase window
    y(hM2+1:end) = fftbuffer(1:hM1);
end

end

