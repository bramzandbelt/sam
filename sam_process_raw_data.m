function sam_process_raw_data(SAM)
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

% 1.2. Dynamic variables
% =========================================================================
    
% Miscellaneous
% -------------------------------------------------------------------------
trueM             = arrayfun(@(x) true(x,1),nStm,'Uni',0);

taskFactors       = [nStm;nRsp;nCnd,nCnd];

% 1.#. Pre-allocate arrays
% =========================================================================

allObs      = dataset({[],'subj'}, ...
                      {[],'sess'}, ...
                      {[],'cnd1'}, ...
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
          {'cnd1','block','stm1','stm2','iSSD','acc','resp','rt','ssd'});
    warning on
    thisData.subj = id(1)*ones(size(thisData,1),1);
    thisData.sess = id(2)*ones(size(thisData,1),1);
    
    % Concatenate dataset arrays
    allObs = [allObs;thisData]; 
end

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
% allData = sortrows(allData,{'subj','sess','cnd1','stm2','ssd','acc','rt'});
                    
% Identify stimulus-condition combinations
s0c2  = allObs.stm1 == 0  & allObs.cnd1 == 2;
s1c2  = allObs.stm1 == 1  & allObs.cnd1 == 2;
s2c4  = allObs.stm1 == 2  & allObs.cnd1 == 4;
s3c4  = allObs.stm1 == 3  & allObs.cnd1 == 4;
s4c4  = allObs.stm1 == 4  & allObs.cnd1 == 4;
s5c4  = allObs.stm1 == 5  & allObs.cnd1 == 4;
s6c6  = allObs.stm1 == 6  & allObs.cnd1 == 6;
s7c6  = allObs.stm1 == 7  & allObs.cnd1 == 6;
s8c6  = allObs.stm1 == 8  & allObs.cnd1 == 6;
s9c6  = allObs.stm1 == 9  & allObs.cnd1 == 6;
s10c6 = allObs.stm1 == 10 & allObs.cnd1 == 6;
s11c6 = allObs.stm1 == 11 & allObs.cnd1 == 6;

% Recode data
allObs.stm1(s0c2)      = 3; allObs.cnd1(s0c2)   = 1;
allObs.stm1(s1c2)      = 4; allObs.cnd1(s1c2)   = 1;
allObs.cnd1(s2c4)      = 2;
allObs.cnd1(s3c4)      = 2;
allObs.cnd1(s4c4)      = 2;
allObs.cnd1(s5c4)      = 2;
allObs.stm1(s6c6)      = 1; allObs.cnd1(s6c6)   = 3;
allObs.stm1(s7c6)      = 2; allObs.cnd1(s7c6)   = 3;
allObs.stm1(s8c6)      = 3; allObs.cnd1(s8c6)   = 3;
allObs.stm1(s9c6)      = 4; allObs.cnd1(s9c6)   = 3;
allObs.stm1(s10c6)     = 5; allObs.cnd1(s10c6)  = 3;
allObs.stm1(s11c6)     = 6; allObs.cnd1(s11c6)  = 3;
                                                  
% Add event onsets and durations
allObs.stm1Ons         = zeros(size(allObs,1),1);
allObs.stm1Dur         = zeros(size(allObs,1),1);
allObs.stm2Ons         = zeros(size(allObs,1),1);
allObs.stm2Dur         = zeros(size(allObs,1),1);
allObs.cnd2            = zeros(size(allObs,1),1);

% Onset and duration of stimulus 1 (go-signal)
iStm1                   = allObs.stm1 > 0;
allObs.stm1Ons(iStm1)  = stmOns(1);
allObs.stm1Dur(iStm1)  = stmDur(1);
                        
% Onset and duration of stimulus 2 (stop-signal)
iStm2                   = allObs.stm2 > 0;
allObs.stm2Ons(iStm2)  = allObs.stm1Ons(iStm2) + allObs.ssd(iStm2);
allObs.stm2Dur(iStm2)  = stmDur(2);
allObs.cnd2(iStm2)     = allObs.cnd1(iStm2);

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
% 4. CLASSIFY TRIALS, COMPUTE DESCRIPTIVES, AND SAVE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subj = unique(allObs.subj);
nSubj = length(subj);

for iSubj = 1:nSubj
 
  % 4.1. Pre-allocate arrays for logging
  % =====================================================================
  
  % Dataset array
	obs           = dataset({zeros(nCnd,1),'nGo'}, ...
                          {zeros(nCnd,1),'nGoCorr'}, ...
                          {zeros(nCnd,1),'nGoComm'}, ...
                          {zeros(nCnd,nSsd),'nStop'}, ...
                          {zeros(nCnd,nSsd),'nStopFailure'}, ...
                          {zeros(nCnd,nSsd),'nStopSuccess'}, ...
                          {zeros(nCnd,1),'pGoCorr'}, ...
                          {zeros(nCnd,1),'pGoComm'}, ...
                          {zeros(nCnd,nSsd),'pStopFailure'}, ...
                          {zeros(nCnd,nSsd),'ssd'}, ...
                          {zeros(nCnd,nSsd),'inhibFunc'}, ...
                          {cell(nCnd,1),'rtGoCorr'}, ...
                          {cell(nCnd,1),'rtGoComm'}, ...
                          {cell(nCnd,nSsd),'rtStopFailure'}, ...
                          {cell(nCnd,nSsd+1),'onset'}, ...
                          {cell(nCnd,nSsd+1),'duration'});
  
  % Trial numbers
  nGo           = zeros(nCnd,1);               % All go
  nGoCorr       = zeros(nCnd,1);               % Correct go
  nGoComm       = zeros(nCnd,1);               % Commission error go
  nStop         = zeros(nCnd,nSsd);           % All stop
  nStopSuccess  = zeros(nCnd,nSsd);           % Successful stop
  nStopFailure  = zeros(nCnd,nSsd);           % Failed stop
  
  % Response probabilities
  pGoCorr       = zeros(nCnd,1);
  pGoComm       = zeros(nCnd,1);
  pStopFailure  = zeros(nCnd,nSsd);
  
  % Response times
  rtGoCorr      = cell(nCnd,1);
  rtGoComm      = cell(nCnd,1);
  rtStopFailure = cell(nCnd,nSsd);
  
  % Stop-signal delays
  ssd           = nan(nCnd,nSsd);
  
  % Inhibition function
  inhibFunc     = nan(nCnd,nSsd);
  
  % Event onsets and durations
  ons           = cell(nCnd,nSsd+1);
  dur           = cell(nCnd,nSsd+1);
  
  for iCnd = 1:nCnd
                    
    % 4.2. Classify Go trials
    % =====================================================================

    % 4.2.1. Trial indices
    % ---------------------------------------------------------------------
    iGo             = find(allObs.subj    == subj(iSubj) & ...
                           allObs.stm2    == 0 & ...
                           allObs.cnd1    == iCnd);

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
                                     allObs.cnd1    == iCnd);
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