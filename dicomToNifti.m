function dicomToNifti(files, outputDir, dim, outputFileName)
%%%%% Convert dicom files to nifti files
%%%%% Written by Carol Jew (January 10, 2018)
%%%%%
%%%%% Take a list a list of dicom files and convert them to nifti files; if
%%%%% 4D nifti files are desired, then the extraneous 3D nifti files
%%%%% generated along the way are also deleted to save space
%%%%%
%%%%% Input:
%%%%%   required:
%%%%%       files: array; list of dicom files
%%%%%   optional:
%%%%%       outputDir: string; directory to save the nifti files (default:
%%%%%       working directory)
%%%%%       dim: integer; 3 or 4 depending on whether you want to output 3D
%%%%%       nifti files or 4D nifti files (default: 3)
%%%%%       outputFileName: string; name for the generated 4D nifti file
%%%%%       (default: 4D.nii)
%%%%% Output: nifti files in the specific output directory

    if nargin < 2
        outputDir = pwd;
    end
    
    if nargin < 3
        dim = 3;
    end
    
    if nargin < 4
        outputFileName = '4D.nii';
    end
    
    if size(files,1) < size(files,2)
        matlabbatch{1}.spm.util.import.dicom.data = cellstr(files)';
    else
        matlabbatch{1}.spm.util.import.dicom.data = cellstr(files);
    end
    matlabbatch{1}.spm.util.import.dicom.root = 'flat';
    matlabbatch{1}.spm.util.import.dicom.outdir = {outputDir};
    matlabbatch{1}.spm.util.import.dicom.protfilter = '.*';
    matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';
    matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 0;
        
    if dim == 4
        matlabbatch{2}.spm.util.cat.vols(1) = cfg_dep('DICOM Import: Converted Images', substruct('.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}, '.','val', '{}',{1}), substruct('.','files'));
        matlabbatch{2}.spm.util.cat.name = outputFileName;
        matlabbatch{2}.spm.util.cat.dtype = 4;
    end
    
    spm_jobman('run', matlabbatch);
    clear matlabbatch
    
    if dim == 4
        cd(outputDir);
        filesToDelete = dir('*.nii');
        filesToDelete(strncmp({filesToDelete.name}, outputFileName, 2)) = [];
        delete(filesToDelete.name);
    end

end