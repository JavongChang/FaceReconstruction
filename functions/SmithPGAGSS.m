function [ b n ] = SmithPGAGSS(texture, U, normal_avg, mus, s)
%SMITHGSS Summary of this function goes here
% 1. Calculate an initial estimate of the field of surface normals n using (12).
% 2. Each normal in the estimated field n undergoes an
%    azimuthal equidistant projection ((3)) to give a
%    vector of transformed coordinates v0.
% 3. The vector of best fit model parameters is given by
%    b = P' * v0 .
% 4. The vector of transformed coordinates corresponding
%    to the best-fit parameters is given by vprime = (PP')v0.
% 5. Using the inverse azimuthal equidistant projection
%    ((4)), find the off-cone best fit surface normal nprime from vprime.
% 6. Find the on-cone surface normal nprimeprime by rotating the
%    off-cone surface normal nprime using nprimeprime(i,j) = theta * nprime(i,j)
% 7. Make n(i,j) = nprimeprime(i,j) and return to Step 2 - Repeat as
%    required

% Texture must be converted to greyscale

    % normalize so it is in the range 0 to 1
    % intensity can never be < 0
    theta = abs(acos(((double(texture) / double(max(max(texture)))))));
    theta(theta < 0) = 0;
    
    n = EstimateNormalsAvg(normal_avg, theta);
    npp = zeros(size(n));

    for i = 1:3      
        if i > 1;
            n = npp;
        end
        
        % Loop until convergence
        ncol = reshape2colvector(n);
        v0 = ncol;
        for p = 1:size(ncol, 2)
            v0(:, p) = logmap(mus(:, p), ncol(:, p));
        end
        v0 = reshape(v0, [], 1); 

        % vector of best-fit parameters
        b = U' * v0;
        % transformed coordinates
        vprime = U * b;

        vcol = reshape2colvector(vprime);
        nprime = vcol;
        for p = 1:size(vcol, 2)
            nprime(:, p) = expmap(mus(:, p), vcol(:, p));
        end
        nprime = reshape(nprime, [], 1); 
        
        % Normalize
        nprime = reshape2colvector(nprime);
        nprime = reshape(bsxfun(@rdivide, nprime, colnorm(nprime)), [], 1); 
        
        npp = OnConeRotation(theta, nprime, s);
        i
    end
    
    n = real(ColVectorToImage3(npp, size(texture, 1), size(texture, 2)));
end