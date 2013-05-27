function out = azimuthal2spherical( projections, mean_normal )
%AZIMUTHAL2SPHERICAL Given a set of points projected using azimuthal
%equidistant projection return their coordinates on a unit sphere
%
% Given a set of projected coordinates re-project them back in to the
% original spherical coordinate space using the inverse azimuthal 
% equidistant projection. Requires the mean surface normal of the 
% original training set at each point to have already been calculated.
%
% projections should be a column vector divisible by two 
% (x1, y1, x2, y2, ...)
% mean_normal should be a column vector divisible by three
% (x1, y1, y2, x2, y2, y3, ...)
%
% Returns a column vector of the projections mapped back in the original
% spherical coordinate space 
% (x1, y1, z1, x2, y2, z2, ...)

N = size(projections, 2);
% from x,y to x,y,z
out = zeros(size(projections, 1) * (3/2), size(projections, 2));

% reshape to vector matrix
vec_mean_normals = reshape(mean_normal, 3, []);
vec_mean_normals = bsxfun(@rdivide, vec_mean_normals, colnorm(vec_mean_normals));

thetaav = elevation(vec_mean_normals(3, :));
% round thetas back in to the range [-pi/2, pi/2]
thetaav(thetaav > pi/2) = thetaav(thetaav > pi/2) - pi;
thetaav(thetaav < -pi/2) = thetaav(thetaav < -pi/2) + pi;
phiav = azimuth(vec_mean_normals(1, :), vec_mean_normals(2, :));
phiav(phiav > pi) = phiav(phiav > pi) - 2 * pi;
phiav(phiav < pi) = phiav(phiav < pi) + 2 * pi;

for i = 1:N
    % as vector matrix
    kset = reshape(projections(:, i), 2, []);
    % find any zero normals as they present a real problem
    % the column indicies are the same in both sets of data
    zero_indices = find(sum(abs(kset)) == 0);

    xs = kset(1, :);
    ys = kset(2, :);
    % theta,phi
    angles = zeros(2, size(kset, 2));
    
    c = sqrt(xs .^ 2 + ys .^ 2);
    recipc = rdivide(ones(1, numel(c)), c);
    
    % thetas = asin[cos(c) * sin(thetaav) - (1/c) * yk * sin(c) * % cos(thetav)]
    s = cos(c) .* sin(thetaav) + recipc .* ys .* sin(c) .* cos(thetaav);
    
    el = asin(s);
    el(el > pi/2) = el(el > pi/2) - pi;
    el(el < -pi/2) = el(el < -pi/2) + pi;
    angles(1, :) = el;
    % phis = phiav + atan(psi)
    [numer, denom] = psi(c, thetaav, xs, ys);
    azi = phiav + atan2(numer, denom);
    azi(azi > pi) = azi(azi > pi) - 2 * pi;
    azi(azi < pi) = azi(azi < pi) + 2 * pi;
    angles(2, :) = azi;
    
    % convert angles to coordinates
    vectors = zeros(size(angles, 1) * (3/2), size(angles, 2));
    vectors(1, :) = cos(angles(2, :)) .* sin(angles(1, :));
    vectors(2, :) = sin(angles(2, :)) .* sin(angles(1, :));
    vectors(3, :) = cos(angles(1, :));

    % reset zero projections back to zero
    vectors(:, zero_indices) = 0;
    
    % reshape back to column vector
    out(:, i) = reshape(vectors, [], 1);
end

end

% theta = (pi / 2) - asin(nz)
function thetas = elevation(zs)
     thetas = (pi / 2) - asin(zs);
end

% phi = atan(ny/nx)
function phis = azimuth(xs, ys)
     phis = atan2(ys, xs);
end

% psi = thetaav != (pi / 2) -> 
%           xk * sin(c) / c * cos(thetaav) * cos(c) - yk * sin(thetav) * sin(c)
%       thetaav == (pi/2)   -> -(xk/yk)
%       thetaav == -(pi/2)  -> xk/yk
function [numer, denom] = psi(c, thetaav, xs, ys)
    N = numel(thetaav);
    % row of zeros
    numer = zeros(1, N);
    denom = zeros(1, N);
        
    for i = 1:N
        if (abs(thetaav(i) - (pi/2)) < eps)
            numer(i) = -xs(i);
            denom(i) = -ys(i);
        elseif (abs(thetaav(i) - (-pi/2)) < eps)
            numer(i) = xs(i);
            denom(i) = ys(i);
        else
            numer(i) = xs(i) * sin(c(i));
            denom(i) = c(i) * cos(thetaav(i)) * cos(c(i)) - ys(i) * sin(thetaav(i)) * sin(c(i));
        end
    end
end