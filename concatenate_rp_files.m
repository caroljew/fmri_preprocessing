function concatenate_rp_files(subjIDbase, dirStructure, outputFileName, outputDir)
%%%%% Concatenate motion regressor files
%%%%% Written by Carol Jew (January 18, 2018)
%%%%% carol.jew@rochester.edu
%%%%%
%%%%% Combine multiple motion regressor files generated during preprocessing
%%%%% into one txt file for use as a single multiple regressor file during
%%%%% 1st level analysis
%%%%%
%%%%% Inputs
%%%%%   required:
%%%%%       -subjIDbase: string; the prefix used for subject names
%%%%%   optional:
%%%%%       -dirStructure: string; the directory structure leading to where
%%%%%       the individual rp*.txt files are housed (default:
%%%%%       'fullfile(pwd, '%s')' where %s is the subjID)
%%%%%       -outputFileName: string; name for the generated file in sprintf
%%%%%       format to use with individual subjIDs (default: 
%%%%%       '%s_concatenated_rp.txt' where %s is the subjID)
%%%%%       -outputDir: string; directory to house the newly generated
%%%%%       files (default: dirstructure, the same directory where the
%%%%%       individual rp*.txt files are housed)

    if nargin < 2
        dirStructure = fullfile(pwd, '%s');
    end
    
    if nargin < 3
        outputFileName = '%s_concatenated_rp.txt';
    end
    
    if nargin < 4
        outputDir = dirStructure;
    end

    %% Find the data
    startingDir = pwd;
    subjDirs = dirType('dir', [subjIDbase, '*']); % locate all the subject directories
    subjDirs = sort_nat({subjDirs.name}); % organize numerically rather than using the default organization
    numSubjs = length(subjDirs);

    for subj = 1:numSubjs
        dataDir = sprintf(dirStructure, subjDirs{subj});
        cd(dataDir);
        
        movementFiles = dirType('file', 'rp*.txt');
        movementFiles = sort_nat({movementFiles.name});
        
        for file = 1:length(movementFiles)
            tmp = load(movementFiles{file});
            
            if file == 1
                tmp2 = tmp;
            else
                tmp2 = [tmp2; tmp];
            end
        end
        
        cd(outputDir);
        save(sprintf(outputFileName, subjDirs{subj}), 'tmp2', '-ascii');
        
        cd(startingDir);
    end
end