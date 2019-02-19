function visualize_movement(subjIDbase, dirStructure, outputFileName, outputDir)
%%%%% Visualize motion regressor files
%%%%% Written by Carol Jew (January 18, 2018)
%%%%% carol.jew@rochester.edu
%%%%%
%%%%% Create a figure that displays how much movement occurred during each
%%%%% run based on the motion regressor files output during the spm
%%%%% preprocessing pipeline
%%%%%
%%%%% Inputs
%%%%%   required:
%%%%%       -subjIDbase: string; the prefix used for subject names
%%%%%   optional:
%%%%%       -dirStructure: string; the directory structure leading to where
%%%%%       the individual rp*.txt files are housed (default:
%%%%%       'fullfile(pwd, '%s')' where %s is the subjID)
%%%%%       -outputFileName: string; name for the generated figure in
%%%%%       sprintf format to use with individual subjIDs (default: 
%%%%%       '%s_movement.tiff' where %s is the subjID)
%%%%%       -outputDir: string; directory to house the newly generated
%%%%%       figures (default: dirStruture, the same directory where the
%%%%%       individual rp*.txt files are housed)
    
    if nargin < 2
        dirStructure = fullfile(pwd, '%s');
    end
    
    if nargin < 3
        outputFileName = '%s_movement.tiff';
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
        
        %% Load the movement files and store them individually
        for run = 1:length(movementFiles)
            eval(sprintf('movement.run%d = load(movementFiles{run});', run));
            
            % find the highest degree of movement in each run for x, y, z
            eval(sprintf('tmp = movement.run%d;', run));
            fprintf('Run %d:', run);

            [~,index1] = max(abs(tmp(:,1)));
            [~,index2] = max(abs(tmp(:,2)));
            [~,index3] = max(abs(tmp(:,3)));

            disp([tmp(index1,1), tmp(index2,2), tmp(index3,3)]);
        end

        %% Generate a figure with all runs shown at once
        figure('units','normalized','outerposition',[0 0 1 1]); % makes the figure the same size as the screen
        len = 2;
        wid = length(movementFiles) / len;

        for run = 1:length(movementFiles)
            subplot(len, wid, run)

            eval(sprintf('tmp = movement.run%d;', run));

            for direction = 1:size(tmp,2)
                plot(tmp(:,direction));
                hold on
                title(sprintf('Run %d', run));
            end

            % suptitle(sprintf('%s', subjDirs(subj).name)); % not using because it changed the size of the first plot
        end
        
        cd(outputDir);
        saveas(gcf, sprintf(outputFileName, subjDirs(subj).name));
        cd(startingDir);
    end
end