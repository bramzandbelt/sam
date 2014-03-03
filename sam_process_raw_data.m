function obs = sam_process_raw_data(SAM)
% SAM_PROCESS_RAW_DATA <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
%
% Here is a description of the data
% 
% Subjects performed 12 sessions
% In each session there were three conditions: 2-choice, 4-choice, 6-choice
%
% Conditions were presented in three blocks. The order of blocks within
% each session was randomized
%
% Each choice condition started with a practice block of 36 trials without
% stop-signals. This no-stop-signal block was followed by  another practice
% block of 36 trials with stop-signals. After the two practice blocks,
% there were two experimental blocks of 120 trials.
%
%
%
%
%
%
%
%
% SYNTAX 
% SAM_PROCESS_RAW_DATA; 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Fri 23 Aug 2013 12:08:07 CDT by bram 
% $Modified: Fri 23 Aug 2013 12:08:07 CDT by bram 
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESSING INPUTS AND SPECIFYING VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Process inputs
% =========================================================================

rawDataDir        = SAM.io.rawDataDir;
workDir           = SAM.io.workDir;

nStm              = SAM.expt.nStm;                                            
nRsp              = SAM.expt.nRsp;
nCnd              = SAM.expt.nCnd;                                            
nSsd              = SAM.expt.nSsd;                                            
trialDur          = SAM.expt.trialDur;
stmOns            = SAM.expt.stmOns;                                        
stmDur            = SAM.expt.stmDur;                                       

modelToFit        = SAM.model.variants.toFit;

qntls             = SAM.optim.cost.stat.cumProb;
minBinSize        = SAM.optim.cost.stat.minBinSize;

% 1.2. Dynamic variables
% =========================================================================
    
% Miscellaneous
% -------------------------------------------------------------------------
trueM             = arrayfun(@(x) true(x,1),nStm,'Uni',0);

nClass            = numel(SAM.model.general.classNames);
taskFactors       = [nStm;nRsp;nCnd,nCnd];

% 1.#. Pre-allocate arrays
% =========================================================================

allObs      = dataset({[],'subj'}, ...
                      {[],'sess'}, ...
                      {[],'cnd'}, ...
                      {[],'block'}, ...
                      {[],'stm1'}, ...
                      {[],'stm2'}, ...
                      {[],'iSSD'}, ...
                      {[],'ssd'}, ...
                      {[],'resp'}, ...
                      {[],'rt'}, ...
                      {[],'acc'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. IMPORT RAW DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 2.1 Identify task performance files
% =========================================================================
file = regexpdir(rawDataDir,'^subject.*-ss.*.txt$');

% 2.2 Import data
% =========================================================================
for iFile = 1:size(file,1)
    
    % Extract path, name, extension of file
    [p n e] = fileparts(file{iFile});
    
    % Extract subject ID and session ID from file name
    [id] = sscanf(n,'subject%d-ss%d');
   
    % Import into dataset array
    warning off
    thisData = dataset('File',file{iFile},'HeaderLines',1,'VarNames', ...
          {'cnd','block','stm1','stm2','iSSD','acc','resp','rt','ssd'});
    warning on
    thisData.subj = id(1)*ones(size(thisData,1),1);
    thisData.sess = id(2)*ones(size(thisData,1),1);
    
    % Concatenate dataset arrays
    allObs = [allObs;thisData]; 
end

% Add variables
allObs.rsp1 = allObs.stm1;
allObs.rsp2 = allObs.stm2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. RECODE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Make coding of correct stimulus-response mapping easier
% 
% Original mapping
% ----------------
% Stim  0   1   2   3   4   5   6   7   8   9   10  11
% Resp  3   4   2   3   4   5   1   2   3   4   5   6
% Cond  2   2   4   4   4   4   6   6   6   6   6   6
%
% New mapping
% ----------------
% Stim  3   4   2   3   4   5   1   2   3   4   5   6
% Resp  3   4   2   3   4   5   1   2   3   4   5   6
% Cond  1   1   2   2   2   2   3   3   3   3   3   3
%

% Sort rows of dataset in the following order: i) subject, ii) session,
% iii) condition, iv) stim2
% allData = sortrows(allData,{'subj','sess','cnd','stm2','ssd','acc','rt'});
                    
% Identify stimulus-condition combinations
s0c2  = allObs.stm1 == 0  & allObs.cnd == 2;
s1c2  = allObs.stm1 == 1  & allObs.cnd == 2;
s2c4  = allObs.stm1 == 2  & allObs.cnd == 4;
s3c4  = allObs.stm1 == 3  & allObs.cnd == 4;
s4c4  = allObs.stm1 == 4  & allObs.cnd == 4;
s5c4  = allObs.stm1 == 5  & allObs.cnd == 4;
s6c6  = allObs.stm1 == 6  & allObs.cnd == 6;
s7c6  = allObs.stm1 == 7  & allObs.cnd == 6;
s8c6  = allObs.stm1 == 8  & allObs.cnd == 6;
s9c6  = allObs.stm1 == 9  & allObs.cnd == 6;
s10c6 = allObs.stm1 == 10 & allObs.cnd == 6;
s11c6 = allObs.stm1 == 11 & allObs.cnd == 6;

% Recode data
allObs.stm1(s0c2)      = 3; allObs.rsp1(s0c2)      = 3; allObs.cnd(s0c2)   = 1;
allObs.stm1(s1c2)      = 4; allObs.rsp1(s1c2)      = 4; allObs.cnd(s1c2)   = 1;
allObs.stm1(s2c4)      = 2; allObs.rsp1(s2c4)      = 2; allObs.cnd(s2c4)   = 2;
allObs.stm1(s3c4)      = 3; allObs.rsp1(s3c4)      = 3; allObs.cnd(s3c4)   = 2;
allObs.stm1(s4c4)      = 4; allObs.rsp1(s4c4)      = 4; allObs.cnd(s4c4)   = 2;
allObs.stm1(s5c4)      = 5; allObs.rsp1(s5c4)      = 5; allObs.cnd(s5c4)   = 2;
allObs.stm1(s6c6)      = 1; allObs.rsp1(s6c6)      = 1; allObs.cnd(s6c6)   = 3;
allObs.stm1(s7c6)      = 2; allObs.rsp1(s7c6)      = 2; allObs.cnd(s7c6)   = 3;
allObs.stm1(s8c6)      = 3; allObs.rsp1(s8c6)      = 3; allObs.cnd(s8c6)   = 3;
allObs.stm1(s9c6)      = 4; allObs.rsp1(s9c6)      = 4; allObs.cnd(s9c6)   = 3;
allObs.stm1(s10c6)     = 5; allObs.rsp1(s10c6)     = 5; allObs.cnd(s10c6)  = 3;
allObs.stm1(s11c6)     = 6; allObs.rsp1(s11c6)     = 6; allObs.cnd(s11c6)  = 3;

% Add event onsets and durations
allObs.stm1Ons         = zeros(size(allObs,1),1);
allObs.stm1Dur         = zeros(size(allObs,1),1);
allObs.stm2Ons         = zeros(size(allObs,1),1);
allObs.stm2Dur         = zeros(size(allObs,1),1);

% Onset and duration of stimulus 1 (go-signal)
iStm1                  = allObs.stm1 > 0;
allObs.stm1Ons(iStm1)  = stmOns(1);
allObs.stm1Dur(iStm1)  = stmDur(1);
                        
% Onset and duration of stimulus 2 (stop-signal)
iStm2                  = allObs.stm2 > 0;
allObs.rsp2(iStm2)     = 1;
allObs.stm2Ons(iStm2)  = allObs.stm1Ons(iStm2) + allObs.ssd(iStm2);
allObs.stm2Dur(iStm2)  = stmDur(2);

allObs = allObs(:,[1 2 4 3 5 14 15 6 16 17 7 8 12 13 9 10 11]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. REMOVE PRACTICE BLOCKS AND OUTLIER TRIALS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 3.1. Remove practice blocks
% =========================================================================
% For each condition and session, blocks 1 and 2 contain practice trials
allObs(allObs.block < 3,:) = [];

% 3.2. Remove Go omission error trials and Go trials with RT < 150 ms
% =========================================================================
allObs(allObs.stm2 == 0 & allObs.rt < 150,:) = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. CATEGORIZE DATA BASED ON MODEL FEATURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Go trials
% =========================================================================================================================
signatureGo   = any(modelToFit.features(:,:,1),2);

if ~isequal(signatureGo,[0 0 0]')
  combiGo       = fullfact(taskFactors(signatureGo,1))';
else
  combiGo       = 1;
end

if isequal(signatureGo,[0 0 0]')
  funGO = @(in1) sprintf('{GO}',in1);
elseif isequal(signatureGo,[1 0 0]')
  funGO = @(in1) sprintf('{GO:s%d}',in1);
elseif isequal(signatureGo,[0 1 0]')
  funGO = @(in1) sprintf('{GO:r%d}',in1);
elseif isequal(signatureGo,[0 0 1]')
  funGO = @(in1) sprintf('{GO:c%d}',in1);
elseif isequal(signatureGo,[1 1 0]')
  funGO = @(in1) sprintf('{GO:s%d,r%d}',in1);
elseif isequal(signatureGo,[1 0 1]')
  funGO = @(in1) sprintf('{GO:s%d,c%d}',in1);
elseif isequal(signatureGo,[0 1 1]')
  funGO = @(in1) sprintf('{GO:r%d,c%d}',in1);
elseif isequal(signatureGo,[1 1 1]')
  funGO = @(in1) sprintf('{GO:s%d,r%d,c%d}',in1);
end

if all(combiGo(:) == 1)
  combiCellGo = mat2cell(combiGo,1,ones(size(combiGo,2),1));
else
  combiCellGo = mat2cell(combiGo,size(combiGo,1),ones(size(combiGo,2),1));
end

tagGo = cellfun(@(in1) ['goTrial_',funGO(in1)],combiCellGo,'Uni',0);

% Stop trials
% =========================================================================================================================
signatureStop         = any(modelToFit.features(:,:,2),2);

if ~isequal(signatureGo,[0 0 0]') && ~isequal(signatureStop,[0 0 0]')
  combiStop             = fullfact([nSsd;taskFactors(signatureGo,1);taskFactors(signatureStop,2)])';
elseif ~isequal(signatureGo,[0 0 0]') && isequal(signatureStop,[0 0 0]')  
  combiStop             = fullfact([nSsd;taskFactors(signatureGo,1)])';
elseif isequal(signatureGo,[0 0 0]') && ~isequal(signatureStop,[0 0 0]')  
  combiStop             = fullfact([nSsd;taskFactors(signatureStop,1)])';
elseif isequal(signatureGo,[0 0 0]') && isequal(signatureStop,[0 0 0]')  
  combiStop             = fullfact([nSsd,1,1])';
end

if isequal(signatureStop,[0 0 0]')
  funSTOP = @(in1) sprintf('{STOP}',in1);
elseif isequal(signatureStop,[1 0 0]')
  funSTOP = @(in1) sprintf('{STOP:s%d}',in1);
elseif isequal(signatureStop,[0 1 0]')
  funSTOP = @(in1) sprintf('{STOP:r%d}',in1);
elseif isequal(signatureStop,[0 0 1]')
  funSTOP = @(in1) sprintf('{STOP:c%d}',in1);
elseif isequal(signatureStop,[1 1 0]')
  funSTOP = @(in1) sprintf('{STOP:s%d,r%d}',in1);
elseif isequal(signatureStop,[1 0 1]')
  funSTOP = @(in1) sprintf('{STOP:s%d,c%d}',in1);
elseif isequal(signatureStop,[0 1 1]')
  funSTOP = @(in1) sprintf('{STOP:r%d,c%d}',in1);
elseif isequal(signatureStop,[1 1 1]')
  funSTOP = @(in1) sprintf('{STOP:s%d,r%d,c%d}',in1);
end

nFactGo = numel(taskFactors(signatureGo,1));
nFactStop = numel(taskFactors(signatureStop,1));

if all(all(combiStop(2:end,:) == 1))
  combiCellStop = mat2cell(combiStop,[1;1;1],ones(size(combiStop,2),1));
else
  combiCellStop = mat2cell(combiStop,[1;nFactGo;nFactStop],ones(size(combiStop,2),1));
end

tagStop = cellfun(@(in1,in2,in3) ['stopTrial_ssd',sprintf('%d',in1),'_',funGO(in2),'_',funSTOP(in3)],combiCellStop(1,:),combiCellStop(2,:),combiCellStop(3,:),'Uni',0);

% All tags
tagAll = [tagGo,tagStop]';

% All combi cells combines
combiCellAll = [combiCellGo,mat2cell(combiCellStop,size(combiCellStop,1),ones(1,size(combiCellStop,2)))];

% Number of trial categories
nTrialCat = numel([tagGo,tagStop]);
nTrialCatGo = numel(tagGo);
nTrialCatStop = numel(tagStop);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. CLASSIFY TRIALS, COMPUTE DESCRIPTIVES, AND SAVE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subj = unique(allObs.subj);
nSubj = length(subj);

for iSubj = 1:nSubj
 
  % 4.1. Pre-allocate arrays for logging
  % =====================================================================
  
  % Dataset array
	obs           = dataset({cell(nTrialCat,1),'trialCat'}, ...
                          {cell(nTrialCat,1),'funGO'}, ...
                          {cell(nTrialCat,1),'funSTOP'}, ...
                          {cell(nTrialCat,1),'onset'}, ...
                          {cell(nTrialCat,1),'duration'}, ...
                          {zeros(nTrialCat,1),'ssd'}, ...
                          {zeros(nTrialCat,1),'nTotal'}, ...
                          {zeros(nTrialCat,1),'nCorr'}, ...
                          {zeros(nTrialCat,1),'nError'}, ...
                          {zeros(nTrialCat,1),'pTotal'}, ...
                          {zeros(nTrialCat,1),'pCorr'}, ...
                          {zeros(nTrialCat,1),'pError'}, ...
                          {cell(nTrialCat,1),'rtCorr'}, ...
                          {cell(nTrialCat,1),'rtError'}, ...
                          {cell(nTrialCat,1),'rtQCorr'}, ...
                          {cell(nTrialCat,1),'rtQError'}, ...
                          {cell(nTrialCat,1),'fCorr'}, ...
                          {cell(nTrialCat,1),'fError'}, ...
                          {cell(nTrialCat,1),'pMassCorr'}, ...
                          {cell(nTrialCat,1),'pMassError'}, ...
                          {cell(nTrialCat,1),'pDefectiveCorr'}, ...
                          {cell(nTrialCat,1),'pDefectiveError'});
                        
	% Some general matrices
  iSsd = [zeros(numel(tagGo),1);cell2mat(combiCellStop(1,:))'];
                        
	for iTrialCat = 1:nTrialCat
    
    obs.trialCat{iTrialCat} = tagAll{iTrialCat};
    
    
    if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*'))
      
      if isequal(signatureGo,[0 0 0]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0);
      elseif isequal(signatureGo,[1 0 0]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0 & ...
                       allObs.stm1    == combiGo(1,iTrialCat));
      elseif isequal(signatureGo,[0 1 0]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0 & ...
                       allObs.rsp1    == combiGo(1,iTrialCat));
      elseif isequal(signatureGo,[0 0 1]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0 & ...
                       allObs.cnd     == combiGo(1,iTrialCat));
      elseif isequal(signatureGo,[1 1 0]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0 & ...
                       allObs.stm1    == combiGo(1,iTrialCat) & ...
                       allObs.rsp1    == combiGo(2,iTrialCat));
      elseif isequal(signatureGo,[1 0 1]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0 & ...
                       allObs.stm1    == combiGo(1,iTrialCat) & ...
                       allObs.cnd     == combiGo(2,iTrialCat));
      elseif isequal(signatureGo,[0 1 1]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0 & ...
                       allObs.rsp1    == combiGo(1,iTrialCat) & ...
                       allObs.cnd     == combiGo(2,iTrialCat));
      elseif isequal(signatureGo,[1 1 1]')
        iSelect = find(allObs.subj    == subj(iSubj) & ...
                       allObs.stm2    == 0 & ...
                       allObs.stm1    == combiGo(1,iTrialCat) & ...
                       allObs.rsp1    == combiGo(2,iTrialCat) & ...
                       allObs.cnd     == combiGo(3,iTrialCat));
      end
    elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*'))
      
      % Select trials based on GO criteria
      if isequal(signatureGo,[0 0 0]')
        iSelectGo = find(allObs.subj    == subj(iSubj));
      elseif isequal(signatureGo,[1 0 0]')
        iSelectGo = find(allObs.subj    == subj(iSubj) & ...
                         allObs.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1));
      elseif isequal(signatureGo,[0 1 0]')
        iSelectGo = find(allObs.subj    == subj(iSubj) & ...
                         allObs.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1));
      elseif isequal(signatureGo,[0 0 1]')
        iSelectGo = find(allObs.subj    == subj(iSubj) & ...
                         allObs.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(1));
      elseif isequal(signatureGo,[1 1 0]')
        iSelectGo = find(allObs.subj    == subj(iSubj) & ...
                         allObs.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1) & ...
                         allObs.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(2));
      elseif isequal(signatureGo,[1 0 1]')
        iSelectGo = find(allObs.subj    == subj(iSubj) & ...
                         allObs.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1) & ...
                         allObs.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(2));
      elseif isequal(signatureGo,[0 1 1]')
        iSelectGo = find(allObs.subj    == subj(iSubj) & ...
                         allObs.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1)& ...
                         allObs.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(2));
      elseif isequal(signatureGo,[1 1 1]')
        iSelectGo = find(allObs.subj    == subj(iSubj) & ...
                         allObs.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1) & ...
                         allObs.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(2) & ...
                         allObs.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(3));
      end
      
      % Select trials based on STOP criteria
      if isequal(signatureStop,[0 0 0]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.stm2    > 0 & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1));
      elseif isequal(signatureStop,[1 0 0]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.stm2    == 1 & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1));
      elseif isequal(signatureStop,[0 1 0]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.stm2    > 0 & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1));
      elseif isequal(signatureStop,[0 0 1]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.stm2    > 0 & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(1));
      elseif isequal(signatureStop,[1 1 0]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(2));
      elseif isequal(signatureStop,[1 0 1]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(2));
      elseif isequal(signatureStop,[0 1 1]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.stm2    > 0 & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(2));
      elseif isequal(signatureStop,[1 1 1]')
        iSelectStop = find(allObs.subj    == subj(iSubj) & ...
                           allObs.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                           allObs.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(2) & ...
                           allObs.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(3));
      end
      
      % Only keep trials satisfying both criteria
      iSelect = intersect(iSelectGo,iSelectStop);
 
    end
    
    iSelectCorr   = intersect(iSelect, find(allObs.acc == 2));
    iSelectError  = intersect(iSelect,find(allObs.acc ~= 2));
        
    % Number of trials
    obs.nTotal(iTrialCat)   = numel(iSelect);
    obs.nCorr(iTrialCat)    = numel(iSelectCorr);
    obs.nError(iTrialCat)   = numel(iSelectError);
    
    % Probability
    obs.pCorr(iTrialCat)    = numel(iSelectCorr)./numel(iSelect);
    obs.pError(iTrialCat)   = numel(iSelectError)./numel(iSelect);
    
    % Response time
    obs.rtCorr{iTrialCat}   = sort(allObs.rt(iSelectCorr));
    obs.rtError{iTrialCat}  = sort(allObs.rt(iSelectError));
    
    obs.ssd(iTrialCat)      = max([0,unique(nonnans(allObs.ssd(iSelect)))]);
    
    
    if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*')) && obs.nCorr(iTrialCat) > 0
      [obs.rtQCorr{iTrialCat}, ...
       obs.pDefectiveCorr{iTrialCat}, ...
       obs.fCorr{iTrialCat}, ...
       obs.pMassCorr{iTrialCat}]  = sam_bin_data(obs.rtCorr{iTrialCat},obs.pCorr(iTrialCat),obs.nCorr(iTrialCat),qntls,minBinSize);
    end
    
    if obs.nError(iTrialCat) > 0
      [obs.rtQError{iTrialCat}, ...
       obs.pDefectiveError{iTrialCat}, ...
       obs.fError{iTrialCat}, ...
       obs.pMassError{iTrialCat}]  = sam_bin_data(obs.rtError{iTrialCat},obs.pError(iTrialCat),obs.nError(iTrialCat),qntls,minBinSize);
    end
    
  end
  
break  
  
  
  for iCnd = 1:nCnd
                    
    % 4.2. Classify Go trials
    % =====================================================================

    % 4.2.1. Trial indices
    % ---------------------------------------------------------------------
    iGo             = find(allObs.subj    == subj(iSubj) & ...
                           allObs.stm2    == 0 & ...
                           allObs.cnd    == iCnd);

    iGoCorr         = intersect(iGo, ...
                                find(allObs.acc == 2));

    iGoComm         = intersect(iGo, ...
                                find(allObs.resp ~= allObs.stm1 & ...
                                     allObs.rt > 0));

    % 4.2.2. Trial numbers
    % ---------------------------------------------------------------------
    nGo(iCnd)       = numel(iGo);
    nGoCorr(iCnd)   = numel(iGoCorr);
    nGoComm(iCnd)   = numel(iGoComm);

    % 4.2.3. Response probabilities
    % ---------------------------------------------------------------------
    pGoCorr(iCnd)   = nGoCorr(iCnd)./nGo(iCnd);
    pGoComm(iCnd)   = nGoComm(iCnd)./nGo(iCnd);
    
    % 4.2.4. Response time
    % ---------------------------------------------------------------------
    rtGoCorr{iCnd}  = sort(allObs.rt(iGoCorr));
    rtGoComm{iCnd}  = sort(allObs.rt(iGoComm));

    % 4.2.5. Onset & duration
    % ---------------------------------------------------------------------
    ons{iCnd,1}     = blkdiag(trueM{:})*[stmOns(1) 0]';
    dur{iCnd,1}     = blkdiag(trueM{:})*[stmDur(1) 0]';
    
    % 4.3. Classify Stop trials
    % =====================================================================

    for iSsd = 1:nSsd

      % 4.3.1. Trial indices
      % -------------------------------------------------------------------
      iStop                   = find(allObs.subj    == subj(iSubj) & ...
                                     allObs.stm2    == 1 & ...
                                     allObs.iSSD    == iSsd & ...
                                     allObs.cnd    == iCnd);
      iStopSuccess            = intersect(iStop, ...
                                          find(allObs.acc == 2));
      iStopFailure            = intersect(iStop, ...
                                          find(allObs.acc ~= 2));

      % 4.3.2. Trial numbers
      % -------------------------------------------------------------------
      nStop(iCnd,iSsd)        = numel(iStop);
      nStopSuccess(iCnd,iSsd) = numel(iStopSuccess);
      nStopFailure(iCnd,iSsd) = numel(iStopFailure);

      % 4.3.3. Response probabilities
      % -------------------------------------------------------------------
      pStopFailure(iCnd,iSsd)    = nStopFailure(iCnd,iSsd)./nStop(iCnd,iSsd);
            
      % 4.3.4. Mean stop signal delay
      % -------------------------------------------------------------------
      if ~isempty(iStop)
          ssd(iCnd,iSsd)      = unique(allObs.ssd(iStop));
      end

      % 4.3.5. Response time
      % -------------------------------------------------------------------
      if ~isempty(iStopFailure)
          rtStopFailure{iCnd,iSsd}  = sort(allObs.rt(iStopFailure));
      end

      % 4.3.6. Onset & duration
      % -------------------------------------------------------------------
      ons{iCnd,iSsd + 1}     = blkdiag(trueM{:})*[stmOns(1) stmOns(1) + ssd(iCnd,iSsd)]';
      dur{iCnd,iSsd + 1}     = blkdiag(trueM{:})*[stmDur(1) stmDur(2)]';
      
    end

    % 4.3.6. Inhibition function
    % ---------------------------------------------------------------------
    inhibFunc(iCnd,:) = reshape(nStopFailure(iCnd,:)./nStop(iCnd,:),1,nSsd);
    
  end
  
  % 4.4. Log data
  % =======================================================================
  obs.nGo           = nGo;
  obs.nGoCorr       = nGoCorr;
  obs.nGoComm       = nGoComm;
    
  obs.nStop         = nStop;
  obs.nStopSuccess  = nStopSuccess;
  obs.nStopFailure  = nStopFailure;
    
  obs.rtGoCorr      = rtGoCorr;
  obs.rtGoComm      = rtGoComm;
  obs.rtStopFailure = rtStopFailure;
    
  obs.ssd           = ssd;
  obs.inhibFunc     = inhibFunc;
    
  obs.pGoCorr       = pGoCorr;
  obs.pGoComm       = pGoComm;
  obs.pStopFailure  = pStopFailure;
    
  obs.onset         = ons;
  obs.duration      = dur;
  
  % 4.5. Save data
  % =======================================================================
  fName = fullfile(outputDir,sprintf('data_preproc_subj%.2d.mat',subj(iSubj)));
  save(fName, 'obs');
  
  fName = fullfile(outputDir,sprintf('all_trial_data_preproc.mat',subj(iSubj)));
  save(fName, 'allObs');
end