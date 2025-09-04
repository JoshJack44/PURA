function pinkNoise = GeneratePinkNoise(sz)
    beta = 1; 
    [u,v] = meshgrid(1:sz, 1:sz); 
    u = u - ceil(sz/2); 
    v = v - ceil(sz/2); 
    R = sqrt(u.^2 + v.^2); 
    R(R==0) = 1; 
    filter = 1 ./ (R.^beta); 
    noise = randn(sz); 
    F = fft2(noise); 
    pinkNoise = real(ifft2(F .* fftshift(filter))); 
    pinkNoise = (pinkNoise - min(pinkNoise(:))) / (max(pinkNoise(:)) - min(pinkNoise(:))); 
    pinkNoise = uint8(pinkNoise * 255); % convert to uint8 grayscale image for Screen 
end
