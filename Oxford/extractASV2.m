clear all
close all
clc

%% Library and paths
run ../vlfeat-0.9.18/toolbox/vl_setup
dataset_dir = './Oxford_dataset/';
Lname = {'bark','bikes','boat','graf','leuven','trees','ubc','wall'};
detectType = 1;

%% Important parameters
isInter = 0; % Default 0. If you set to 1 then the interpolation will be activated.
des = 'sift'; % There are three type descriptor in vlfeat covdet. You can choose 'sift', 'liop', or 'patch'.
opt.sc_min = 1/6; % The smallest size.
opt.sc_max = 3; % The biggest size.
opt.ns = 10; % Number of the sampled scales.

%% (Optional, usually you don't want to change these.)
% The following parameters belongs to the extended version of ASV.
% While scale space is studied in the original setting,
% rotation might also help to improve the performace.
% We do not change any of the rotation parameters for convience,
% but you are free to try these. The performance will be further improved.
opt.rc_min = 0; % The smallest angle.
opt.rc_max = 0; % The biggest angle.
opt.nr = 1; % Number of the sampled angles.

numTypes = 8;
numImages = 6;
iterations = numTypes * numImages;

%% Read images into cell array
tic
images = cell(0);
for k = 1:iterations
    i = floor((k-1)/numImages) + 1;
    j = mod(k - 1, numImages) + 1;
    img = imread([dataset_dir, Lname{i}, '/img', num2str(j), '.ppm']);
    if size(img, 3) > 1
        img = rgb2gray(img);
    end
    images{end+1} = img;
end
toc

%% Extract the descriptor from the whole data
tic
parfor k = 1:iterations
    i = floor((k-1)/numImages) + 1;
    j = mod(k - 1, numImages) + 1;

    fprintf('i:%d  j:%d\n',i,j)
    %% Initialize the detected frame for fair comparison
    [f,d_sift] = extract(images{k},'sift'); % always use sift as standard

    %% Remove same position points
    id_used = (1);
    tempLine = zeros(1);
    for f_i = 1:size(f,2)
        temp = f(:,f_i)';
        line = (temp(1:2));
        if f_i>1 && norm(tempLine(1:2)-line(1:2)) ~= 0
            id_used = [id_used,f_i];
        end
        tempLine = line;
    end

    f = f(:,id_used);
    d_sift = d_sift(:,id_used);

    %% ASV(1S): median thresholding
    d_asv = vl_asvcovdet(images{k}, opt, f, des, isInter);       

    %% Save
    nameF = ['./imageFD/DoG/',num2str(i),'/',num2str(j)];
    if size(dir(nameF),1) ==0
        mkdir(nameF)
    end
    parsave([nameF,'/ASV2'], f, d_asv, opt);
end
toc

function parsave(fname, f, d_asv, opt)
    save(fname, 'f', 'd_asv', 'opt');
end
