%% Assumes CreateData has been run. Calculates all spherical medians.

% Allows me to use a subset of the training_set
normals_set = cellfun(@(x) getfield(x, 'alignedNormals'), I_model, 'UniformOutput', false);
normals_set = cellfun(@(x) Image2ColVector3(x), normals_set, 'UniformOutput', false);
normals_set = cell2mat(normals_set');
%normals_set = normals_set(:, 1:3);

mean_normals_set = sum(normals_set, 2);
mean_normals_set = mean_normals_set/size(normals_set, 2);

% need to calculate for every point (53490) but we have a single column so
% need to run over all 160470 in 3s
% N = number of vertices * 3
N = size(normals_set, 1);
mus = zeros(3, N/3);

textprogressbar('Generating intrinsic means for each normal: ');
for i = 1:3:N
    normalp = [normals_set(i, :); normals_set(i+1, :); normals_set(i+2, :)];
    % column vector
    normalp = reshape(normalp, [], 1);
    mu = fminsearch(@(x) sphericalmedian(x, normalp), normalp(1:3));

    mus(:, ceil(i / 3)) = mu;  
    textprogressbar((ceil((i/N)*100)));
end
textprogressbar(' done');

% column vector
%mus = reshape(mus, [], 1);

clear i;
clear normalp;
clear mu;

%% Calculate D

% K = number of faces
K = size(normals_set, 2);
% N = number of vertices
N = N / 3;

D = zeros(N * 3, K);

textprogressbar('Generating D: ');
% for each face
for i = 1:K
    normals = reshape(normals_set(:, i), [3 numel(normals_set(:, i))/3]);
    vk = zeros(3, N);
    % for all normals
    parfor k = 1:N
        vk(:, k) = logmap(mus(:, k), normals(:, k));
    end
    D(:, i) = reshape(vk, [], 1);
    textprogressbar(((i/K)*100));
end
textprogressbar(' done');

clear normals;
clear vk;

%% Calculate Average D

disp('Generating DAvg...');
DAvg = zeros(N * 3, 1);
normals = reshape(mean_normals_set, [3 numel(mean_normals_set)/3]);
vk = zeros(3, N);

% for all normals
parfor k = 1:N   
    vk(:, k) = logmap(mus(:, k), normals(:, k));
end
DAvg(:, 1) = reshape(vk, [], 1);
disp('Finished generating DAvg.');

clear normals;
clear vk;
clear i;
clear k;

UPGA = myGPCA(D, 199, 0);

save('pga.mat', D, DAvg, UPGA, mus);