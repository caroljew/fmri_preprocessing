function preprocessingPipeline(funcFiles, anatFile, numVols, TR, acquisitionOrder, numSlices, refSlice, normVersion, normVoxSize, smoothFWHM)
%%%%% Preprocessing pipeline for fMRI data
%%%%% Written by Carol Jew (January 12, 2018)
%%%%% carol.jew@rochester.edu
%%%%%
%%%%% Take a list of functional and anatomical nifti files and
%%%%% perform slice time correction, realignment, coregistration, 
%%%%% segmentation, normalization, and smoothing.
%%%%%
%%%%% Input:
%%%%%   required:
%%%%%       - funcFiles: string; full path to functional files
%%%%%       - anatFile: string; full path to anatomical file for
%%%%%         coregistration/alignment
%%%%%       - TR: integer
%%%%%       - acquisitionOrder: string; interleaved, ascending, descending
%%%%%       - slices: integer
%%%%%       - refSlice: integer
%%%%%   optional:
%%%%%       - normVersion: 'new' or 'old' (default: 'new')
%%%%%       - normVoxSize: 1 or 3 integers; the new voxel size for
%%%%%         normalization; if only 1 integer is provided, isotropic
%%%%%         voxels will be created (default: 2 x 2 x 2)
%%%%%       - smoothFWHM: 1 or 3 integers; the smoothing kernel; if only 1
%%%%%         integer is provided, isotropic smoothing will be applied
%%%%%         (default: 8 x 8 x 8)
%%%%%       
%%%%% Output: preprocessed functional and anatomical files after each step
%%%%% in same directory containing the originally provided functional files

    global spmDir
    
    %% Defining the defaults for optional arguments
    if nargin < 8
        normVersion = 'new';
    elseif nargin >= 8
        if ~strcmp(normVersion, 'new') && ~strcmp(normVersion, 'old')
            error('Please specify the normalization version as ''new'' or ''old''');
        end
    end
    
    if nargin < 9
        normVoxSize = [2 2 2];
    elseif nargin >= 9
        if length(normVoxSize) < 3
            normVoxSize = [normVoxSize normVoxSize normVoxSize];
        end
    end
    
    if nargin < 10
        smoothFWHM = [8 8 8];
    elseif nargin >= 10
        if length(smoothFWHM) < 3
            smoothFWHM = [smoothFWHM smoothFWHM smoothFWHM];
        end
    end
    
    %% Slice timing correction
    matlabbatch{1}.spm.temporal.st.scans = cell(cell(length(funcFiles),1));
    for run = 1:length(funcFiles)
        for vol = 1:numVols
            matlabbatch{1}.spm.temporal.st.scans{run}{vol,1} = sprintf('%s,%i', funcFiles{run}, vol);
        end
    end
    
    matlabbatch{1}.spm.temporal.st.nslices = numSlices;
    matlabbatch{1}.spm.temporal.st.tr = TR;
    matlabbatch{1}.spm.temporal.st.ta = TR - (TR / numSlices);
    
    if strcmp(acquisitionOrder, 'interleaved')
        matlabbatch{1}.spm.temporal.st.so = [1:2:numSlices, 2:2:numSlices];
    elseif strcmp(acquisitionOrder, 'ascending')
        matlabbatch{1}.spm.temporal.st.so = 1:1:numSlices;
    elseif strcmp(acquisitionOrder, 'descending')
        matlabbatch{1}.spm.temporal.st.so = numSlices:-1:1;
    else
        error('The specified value for ''acquisition order'' is not recognized. Please specify either ''ascending'', ''descending'', or ''interleaved''');
    end
    
    matlabbatch{1}.spm.temporal.st.refslice = refSlice;
    matlabbatch{1}.spm.temporal.st.prefix = 'a';
    
    %% Realign & unwarp
    for run = 1:length(funcFiles)
        dependencySess = sprintf('Slice Timing: Slice Timing Corr. Images (Sess %d)', run);
        matlabbatch{2}.spm.spatial.realignunwarp.data(run).scans(1) = cfg_dep(dependencySess, substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{run}, '.','files'));
        matlabbatch{2}.spm.spatial.realignunwarp.data(run).pmscan = '';
    end
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.quality = 0.9;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.sep = 4;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.fwhm = 5;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.rtm = 1;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.einterp = 2;
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.ewrap = [0 0 0];
    matlabbatch{2}.spm.spatial.realignunwarp.eoptions.weight = '';
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.basfcn = [12 12];
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.regorder = 1;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.lambda = 100000;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.jm = 0;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.fot = [4 5];
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.sot = [];
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.uwfwhm = 4;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.rem = 1;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.noi = 5;
    matlabbatch{2}.spm.spatial.realignunwarp.uweoptions.expround = 'Average';
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.uwwhich = [2 1];
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.rinterp = 4;
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.wrap = [0 0 0];
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.mask = 1;
    matlabbatch{2}.spm.spatial.realignunwarp.uwroptions.prefix = 'u';
    
    %% SPM12 Normalization
    if strcmp(normVersion, 'new') % SPM12 default normalization
        %% Check whether the origin of the anatomical file has been checked
        originCheck = input('Have you already checked the origin of the specified anatomical file? [y/n] ','s');
        if ~strcmpi(originCheck, 'y')
            error('Please check the origin of the specified anatomical file before proceeding with preprocessing.');
        end
        
        %% Coregistration
        matlabbatch{3}.spm.spatial.coreg.estimate.ref(1) = cfg_dep('Realign & Unwarp: Unwarped Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','meanuwr'));
        matlabbatch{3}.spm.spatial.coreg.estimate.source = {[anatFile, ',1']};
        matlabbatch{3}.spm.spatial.coreg.estimate.other = {''};
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.cost_fun = 'nmi';
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.sep = [4 2];
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
        matlabbatch{3}.spm.spatial.coreg.estimate.eoptions.fwhm = [7 7];
    
        %% Segment
        matlabbatch{4}.spm.spatial.preproc.channel.vols(1) = cfg_dep('Coregister: Estimate: Coregistered Images', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','cfiles'));
        matlabbatch{4}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{4}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{4}.spm.spatial.preproc.channel.write = [1 1];
        matlabbatch{4}.spm.spatial.preproc.tissue(1).tpm = {[spmDir, '/tpm/TPM.nii,1']};
        matlabbatch{4}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{4}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(2).tpm = {[spmDir, '/tpm/TPM.nii,2']};
        matlabbatch{4}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{4}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(3).tpm = {[spmDir, '/tpm/TPM.nii,3']};
        matlabbatch{4}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(4).tpm = {[spmDir, '/tpm/TPM.nii,4']};
        matlabbatch{4}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{4}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(5).tpm = {[spmDir, '/tpm/TPM.nii,5']};
        matlabbatch{4}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{4}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(6).tpm = {[spmDir, '/tpm/TPM.nii,6']};
        matlabbatch{4}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{4}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{4}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{4}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{4}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{4}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{4}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{4}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{4}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{4}.spm.spatial.preproc.warp.write = [0 1];

        %% Normalize
        matlabbatch{5}.spm.spatial.normalise.write.subj.def(1) = cfg_dep('Segment: Forward Deformations', substruct('.','val', '{}',{4}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','fordef', '()',{':'}));

        for run = 1:length(funcFiles)
            dependencySess = sprintf('Realign & Unwarp: Unwarped Images (Sess %d)', run);
            matlabbatch{5}.spm.spatial.normalise.write.subj.resample(run) = cfg_dep(dependencySess, substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{run}, '.','uwrfiles'));
        end
        matlabbatch{5}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70
                                                                  78 76 85];
        matlabbatch{5}.spm.spatial.normalise.write.woptions.vox = normVoxSize;
        matlabbatch{5}.spm.spatial.normalise.write.woptions.interp = 4;
        matlabbatch{5}.spm.spatial.normalise.write.woptions.prefix = 'w12';

        %%% Smoothing
        % dependencies within smoothing don't function properly due to the change in the normalization prefix
        % matlabbatch{6}.spm.spatial.smooth.data(1) = cfg_dep('Normalise: Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{5}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        % matlabbatch{6}.spm.spatial.smooth.fwhm = smoothFWHM;
        % matlabbatch{6}.spm.spatial.smooth.dtype = 0;
        % matlabbatch{6}.spm.spatial.smooth.im = 0;
        % matlabbatch{6}.spm.spatial.smooth.prefix = 's';
    
    %% SPM8 Normalization
    elseif strcmp(normVersion, 'old') % SPM8 direct normalization method where functional data is normalized to the EPI template; "old normalise" in SPM12
        %% Old Normalize (directly based on the functional data)
        matlabbatch{3}.spm.tools.oldnorm.estwrite.subj.source(1) = cfg_dep('Realign & Unwarp: Unwarped Mean Image', substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','meanuwr'));
        matlabbatch{3}.spm.tools.oldnorm.estwrite.subj.wtsrc = '';
        
        for run = 1:length(funcFiles)
            dependencySess = sprintf('Realign & Unwarp: Unwarped Images (Sess %d)', run);
            matlabbatch{3}.spm.tools.oldnorm.estwrite.subj.resample(run) = cfg_dep(dependencySess, substruct('.','val', '{}',{2}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','sess', '()',{run}, '.','uwrfiles'));
        end
        
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.template = {[spmDir, '/toolbox/OldNorm/EPI.nii,1']};
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.weight = '';
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.smosrc = 8;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.smoref = 0;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.regtype = 'mni';
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.cutoff = 25;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.nits = 16;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.eoptions.reg = 1;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.roptions.preserve = 0;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.roptions.bb = [-78 -112 -70
                                                                 78 76 85];
        matlabbatch{3}.spm.tools.oldnorm.estwrite.roptions.vox = normVoxSize;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.roptions.interp = 1;
        matlabbatch{3}.spm.tools.oldnorm.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{3}.spm.tools.oldnorm.estwrite.roptions.prefix = 'w8';
        
        
        %%% Smoothing
        % dependencies within smoothing don't function properly due to the change in the normalization prefix
        % matlabbatch{4}.spm.spatial.smooth.data(1) = cfg_dep('Old Normalise: Estimate & Write: Normalised Images (Subj 1)', substruct('.','val', '{}',{3}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('()',{1}, '.','files'));
        % matlabbatch{4}.spm.spatial.smooth.fwhm = smoothFWHM;
        % matlabbatch{4}.spm.spatial.smooth.dtype = 0;
        % matlabbatch{4}.spm.spatial.smooth.im = 0;
        % matlabbatch{4}.spm.spatial.smooth.prefix = 's';
    end
    spm_jobman('run', matlabbatch);
    
    %% Smoothing
    % need this separate smoothing module because the change to the default
    % normalization prefix messes up the dependencies needed for smoothing
    numJobs = length(matlabbatch);
    if strcmp(normVersion, 'new')
        normalizedFiles = dirType('file', sprintf('%s*.nii', matlabbatch{numJobs}.spm.spatial.normalise.write.woptions.prefix));
    elseif strcmp(normVersion, 'old')
        normalizedFiles = dirType('file', sprintf('%s*.nii', matlabbatch{numJobs}.spm.tools.oldnorm.estwrite.roptions.prefix));
    end
    
    tmp = cell(1,length(normalizedFiles));
    for run = 1:length(normalizedFiles)
        for vol = 1:numVols
            tmp{run}{vol,1} = sprintf('%s,%i', normalizedFiles(run).name, vol);
        end
    end
    clear matlabbatch

    matlabbatch{1}.spm.spatial.smooth.data = vertcat(tmp{:});
    matlabbatch{1}.spm.spatial.smooth.fwhm = smoothFWHM;
    matlabbatch{1}.spm.spatial.smooth.dtype = 0;
    matlabbatch{1}.spm.spatial.smooth.im = 0;
    matlabbatch{1}.spm.spatial.smooth.prefix = 's';
    spm_jobman('run', matlabbatch)
    clear matlabbatch
end