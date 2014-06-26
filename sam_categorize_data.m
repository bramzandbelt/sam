function obs = sam_categorize_data(SAM)
% SAM_CATEGORIZE_DATA Categorizes behavioral data into different trial types
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% obs = SAM_CATEGORIZE_DATA(file); 
% 
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Wed 12 Mar 2014 14:16:31 CDT by bram 
% $Modified: Wed 12 Mar 2014 14:16:31 CDT by bram 

 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESSING INPUTS AND SPECIFYING VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Process inputs
% =========================================================================

file              = SAM.io.behavFile;

nStm              = SAM.expt.nStm;                                            
nRsp              = SAM.expt.nRsp;
nCnd              = SAM.expt.nCnd;                                            
nSsd              = SAM.expt.nSsd;                                            
stmOns            = SAM.expt.stmOns;                                        
stmDur            = SAM.expt.stmDur;                                       

modelToFit        = SAM.model.variants.toFit;

simScope          = SAM.sim.scope;

cumProb           = SAM.optim.cost.stat.cumProb;
minBinSize        = SAM.optim.cost.stat.minBinSize;

% 1.2. Dynamic variables
% =========================================================================
    
% Miscellaneous
% -------------------------------------------------------------------------
trueM             = arrayfun(@(x) true(x,1),nStm,'Uni',0);

taskFactors       = [nStm;nRsp;nCnd,nCnd];

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. LOAD BEHAVIORAL DATA
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load the variable data from the behavior file
load(file,'data');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. CATEGORIZE DATA BASED ON MODEL FEATURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Go trials
% =========================================================================
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

nFactGo = numel(taskFactors(signatureGo,1));

if all(combiGo(:) == 1)
  combiCellGo = mat2cell(combiGo,1,ones(size(combiGo,2),1));
else
  combiCellGo = mat2cell(combiGo,size(combiGo,1),ones(size(combiGo,2),1));
end

tagGo = cellfun(@(in1) ['goTrial_',funGO(in1)],combiCellGo,'Uni',0);

% All tags
tagAll = tagGo';

% Number of trial categories
nTrialCat = numel(tagGo);
nTrialCatGo = numel(tagGo);

switch lower(simScope)
  case 'go'
  case 'all'
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

    nFactStop = numel(taskFactors(signatureStop,1));

    if all(all(combiStop(2:end,:) == 1))
      combiCellStop = mat2cell(combiStop,[1;1;1],ones(size(combiStop,2),1));
    else
      combiCellStop = mat2cell(combiStop,[1;nFactGo;nFactStop],ones(size(combiStop,2),1));
    end

    tagStop = cellfun(@(in1,in2,in3) ['stopTrial_{ssd',sprintf('%d',in1),'}_',funGO(in2),'_',funSTOP(in3)],combiCellStop(1,:),combiCellStop(2,:),combiCellStop(3,:),'Uni',0);
    
    % All tags
    tagAll = [tagGo,tagStop]';
    
    % Number of trial categories
    nTrialCat = numel([tagGo,tagStop]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. CLASSIFY TRIALS, COMPUTE DESCRIPTIVES, AND SAVE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 4.1. Pre-allocate arrays for logging
% =====================================================================

% Dataset array
obs           = dataset({cell(nTrialCat,1),'trialCat'}, ...
                        {cell(nTrialCat,1),'funGO'}, ...
                        {cell(nTrialCat,1),'funSTOP'}, ...
                        {cell(nTrialCat,1),'onset'}, ...
                        {cell(nTrialCat,1),'duration'}, ...
                        {nan(nTrialCat,1),'ssd'}, ...
                        {nan(nTrialCat,1),'nTotal'}, ...
                        {nan(nTrialCat,1),'nGoCCorr'}, ...
                        {nan(nTrialCat,1),'nGoCError'}, ...
                        {nan(nTrialCat,1),'nStopICorr'}, ...
                        {nan(nTrialCat,1),'nStopIErrorCCorr'}, ...
                        {nan(nTrialCat,1),'nStopIErrorCError'}, ...
                        {nan(nTrialCat,1),'pTotal'}, ...
                        {nan(nTrialCat,1),'pGoCCorr'}, ...
                        {nan(nTrialCat,1),'pGoCError'}, ...
                        {nan(nTrialCat,1),'pStopICorr'}, ...
                        {nan(nTrialCat,1),'pStopIErrorCCorr'}, ...
                        {nan(nTrialCat,1),'pStopIErrorCError'}, ...
                        {cell(nTrialCat,1),'rtGoCCorr'}, ...
                        {cell(nTrialCat,1),'rtGoCError'}, ...
                        {cell(nTrialCat,1),'rtStopICorr'}, ...
                        {cell(nTrialCat,1),'rtStopIErrorCCorr'}, ...
                        {cell(nTrialCat,1),'rtStopIErrorCError'}, ...
                        {cell(nTrialCat,1),'rtQGoCCorr'}, ...
                        {cell(nTrialCat,1),'rtQGoCError'}, ...
                        {cell(nTrialCat,1),'rtQStopICorr'}, ...
                        {cell(nTrialCat,1),'rtQStopIErrorCCorr'}, ...
                        {cell(nTrialCat,1),'rtQStopIErrorCError'}, ...
                        {cell(nTrialCat,1),'cumProbGoCCorr'}, ...
                        {cell(nTrialCat,1),'cumProbGoCError'}, ...
                        {cell(nTrialCat,1),'cumProbStopICorr'}, ...
                        {cell(nTrialCat,1),'cumProbStopIErrorCCorr'}, ...
                        {cell(nTrialCat,1),'cumProbStopIErrorCError'}, ...
                        {cell(nTrialCat,1),'cumProbDefectiveGoCCorr'}, ...
                        {cell(nTrialCat,1),'cumProbDefectiveGoCError'}, ...
                        {cell(nTrialCat,1),'cumProbDefectiveStopICorr'}, ...
                        {cell(nTrialCat,1),'cumProbDefectiveStopIErrorCCorr'}, ...
                        {cell(nTrialCat,1),'cumProbDefectiveStopIErrorCError'}, ...
                        {cell(nTrialCat,1),'probMassGoCCorr'}, ...
                        {cell(nTrialCat,1),'probMassGoCError'}, ...
                        {cell(nTrialCat,1),'probMassStopICorr'}, ...
                        {cell(nTrialCat,1),'probMassStopIErrorCCorr'}, ...
                        {cell(nTrialCat,1),'probMassStopIErrorCError'}, ...
                        {cell(nTrialCat,1),'probMassDefectiveGoCCorr'}, ...
                        {cell(nTrialCat,1),'probMassDefectiveGoCError'}, ...
                        {cell(nTrialCat,1),'probMassDefectiveStopICorr'}, ...
                        {cell(nTrialCat,1),'probMassDefectiveStopIErrorCCorr'}, ...
                        {cell(nTrialCat,1),'probMassDefectiveStopIErrorCError'});                    

for iTrialCat = 1:nTrialCat

  obs.trialCat{iTrialCat} = tagAll{iTrialCat};

  % 4.2. Classify on the basis of trial (go/stop) and experimental factors
  % (stimulus, response, condition)
  % =======================================================================
  
  % If this is a Go trial
  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))

    if isequal(signatureGo,[0 0 0]')
      iSelect = find(data.stm2    == 0);
    elseif isequal(signatureGo,[1 0 0]')
      iSelect = find(data.stm2    == 0 & ...
                     data.stm1    == combiGo(1,iTrialCat));
    elseif isequal(signatureGo,[0 1 0]')
      iSelect = find(data.stm2    == 0 & ...
                     data.rsp1    == combiGo(1,iTrialCat));
    elseif isequal(signatureGo,[0 0 1]')
      iSelect = find(data.stm2    == 0 & ...
                     data.cnd     == combiGo(1,iTrialCat));
    elseif isequal(signatureGo,[1 1 0]')
      iSelect = find(data.stm2    == 0 & ...
                     data.stm1    == combiGo(1,iTrialCat) & ...
                     data.rsp1    == combiGo(2,iTrialCat));
    elseif isequal(signatureGo,[1 0 1]')
      iSelect = find(data.stm2    == 0 & ...
                     data.stm1    == combiGo(1,iTrialCat) & ...
                     data.cnd     == combiGo(2,iTrialCat));
    elseif isequal(signatureGo,[0 1 1]')
      iSelect = find(data.stm2    == 0 & ...
                     data.rsp1    == combiGo(1,iTrialCat) & ...
                     data.cnd     == combiGo(2,iTrialCat));
    elseif isequal(signatureGo,[1 1 1]')
      iSelect = find(data.stm2    == 0 & ...
                     data.stm1    == combiGo(1,iTrialCat) & ...
                     data.rsp1    == combiGo(2,iTrialCat) & ...
                     data.cnd     == combiGo(3,iTrialCat));
    end

  % If this is a Stop trial 
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))

    % Select trials based on GO criteria
    if isequal(signatureGo,[0 0 0]')
      iSelectGo = find(data.subj);
    elseif isequal(signatureGo,[1 0 0]')
      iSelectGo = find(data.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1));
    elseif isequal(signatureGo,[0 1 0]')
      iSelectGo = find(data.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1));
    elseif isequal(signatureGo,[0 0 1]')
      iSelectGo = find(data.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(1));
    elseif isequal(signatureGo,[1 1 0]')
      iSelectGo = find(data.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1) & ...
                       data.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(2));
    elseif isequal(signatureGo,[1 0 1]')
      iSelectGo = find(data.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1) & ...
                       data.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(2));
    elseif isequal(signatureGo,[0 1 1]')
      iSelectGo = find(data.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1)& ...
                       data.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(2));
    elseif isequal(signatureGo,[1 1 1]')
      iSelectGo = find(data.stm1    == combiCellStop{2,iTrialCat-nTrialCatGo}(1) & ...
                       data.rsp1    == combiCellStop{2,iTrialCat-nTrialCatGo}(2) & ...
                       data.cnd     == combiCellStop{2,iTrialCat-nTrialCatGo}(3));
    end

    % Select trials based on STOP criteria
    if isequal(signatureStop,[0 0 0]')
      iSelectStop = find(data.stm2    > 0 & ...
                         data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1));
    elseif isequal(signatureStop,[1 0 0]')
      iSelectStop = find(data.stm2    == 1 & ...
                         data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                         data.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1));
    elseif isequal(signatureStop,[0 1 0]')
      iSelectStop = find(data.stm2    > 0 & ...
                         data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                         data.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1));
    elseif isequal(signatureStop,[0 0 1]')
      iSelectStop = find(data.stm2    > 0 & ...
                         data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                         data.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(1));
    elseif isequal(signatureStop,[1 1 0]')
      iSelectStop = find(data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                         data.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                         data.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(2));
    elseif isequal(signatureStop,[1 0 1]')
      iSelectStop = find(data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                         data.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                         data.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(2));
    elseif isequal(signatureStop,[0 1 1]')
      iSelectStop = find(data.stm2    > 0 & ...
                         data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                         data.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                         data.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(2));
    elseif isequal(signatureStop,[1 1 1]')
      iSelectStop = find(data.iSSD    == combiCellStop{1,iTrialCat-nTrialCatGo}(1) & ...
                         data.stm2    == combiCellStop{3,iTrialCat-nTrialCatGo}(1) & ...
                         data.rsp2    == combiCellStop{3,iTrialCat-nTrialCatGo}(2) & ...
                         data.cnd     == combiCellStop{3,iTrialCat-nTrialCatGo}(3));
    end

    % Only keep trials satisfying both criteria
    iSelect = intersect(iSelectGo,iSelectStop);

  end

  
  % 4.3. Narrow down the classification based on trial type (correct
  % choice, choice error)
  % =======================================================================
  
  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))
      
      iGoCCorr              = intersect(iSelect,find(data.rsp1 == data.resp));
      iGoCError             = intersect(iSelect,find(data.rsp1 ~= data.resp));
      
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
      
      iStopICorr            = intersect(iSelect,find(data.rt == 0));
      iStopIErrorCCorr      = intersect(iSelect,find(data.rt > 0 & data.rsp1 == data.resp));
      iStopIErrorCError     = intersect(iSelect,find(data.rt > 0 & data.rsp1 ~= data.resp));
  end
  
  % Number of trials
  % -----------------------------------------------------------------------
  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))
      % Compute
      nGoCCorr                          = numel(find(iGoCCorr));
      nGoCError                         = numel(find(iGoCError));
      nGoTotal                          = nGoCCorr + nGoCError;
      
      % Log
      obs.nTotal(iTrialCat)             = nGoTotal;
      obs.nGoCCorr(iTrialCat)           = nGoCCorr;
      obs.nGoCError(iTrialCat)          = nGoCError;
      
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
      % Compute
      nStopICorr                        = numel(find(iStopICorr));
      nStopIErrorCCorr                  = numel(find(iStopIErrorCCorr));
      nStopIErrorCError                 = numel(find(iStopIErrorCError));
      nStopTotal                        = nStopICorr + nStopIErrorCCorr + nStopIErrorCError;
      
      % Log
      obs.nTotal(iTrialCat)             = nStopTotal;
      obs.nStopICorr(iTrialCat)         = nStopICorr;
      obs.nStopIErrorCCorr(iTrialCat)   = nStopIErrorCCorr;
      obs.nStopIErrorCError(iTrialCat)  = nStopIErrorCError;
  end
  
  % Trial probabilities
  % -----------------------------------------------------------------------
  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))
      % Compute
      if nGoTotal > 0
          pGoCCorr                          = nGoCCorr/nGoTotal;
          pGoCError                         = nGoCError/nGoTotal;
      else
          pGoCCorr                          = 0;
          pGoCError                         = 0;
      end
      
      % Log
      obs.pTotal(iTrialCat)             = pGoCCorr + pGoCError;
      obs.pGoCCorr(iTrialCat)           = pGoCCorr;
      obs.pGoCError(iTrialCat)          = pGoCError;
      
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
      % Compute
      if nStopTotal > 0
          pStopICorr                        = nStopICorr/nStopTotal;
          pStopIErrorCCorr                  = nStopIErrorCCorr/nStopTotal;
          pStopIErrorCError                 = nStopIErrorCError/nStopTotal;
      else
          pStopICorr                        = 0;
          pStopIErrorCCorr                  = 0;
          pStopIErrorCError                 = 0;
      end
      
      % Log
      obs.pTotal(iTrialCat)             = pStopICorr + pStopIErrorCCorr + pStopIErrorCError;
      obs.pStopICorr(iTrialCat)         = pStopICorr;
      obs.pStopIErrorCCorr(iTrialCat)   = pStopIErrorCCorr;
      obs.pStopIErrorCError(iTrialCat)  = pStopIErrorCError;
      
  end
  
  % Response time
  % -----------------------------------------------------------------------
  
  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))
    if nGoCCorr > 0
        % Compute
        rtGoCCorr = sort(data.rt(iGoCCorr));
        
        % Log
        obs.rtGoCCorr{iTrialCat} = rtGoCCorr;
    end
    
    if nGoCError > 0
        % Compute
        rtGoCError = sort(data.rt(iGoCError));
        
        % Note: stimOns for iTargetGO and iNonTargetGO are the same; I use 
        % iTargetGO instead of iNonTargetGO because iTargetGO is always a 
        % scalar, iNonTargetGO not.
      
        % Log
        obs.rtGoCError{iTrialCat} = rtGoCError;
    end
    
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
    if nStopICorr > 0
        % Compute
        rtStopICorr = sort(data.rt(iStopICorr));
        
        % Log
        obs.rtStopICorr{iTrialCat} = rtStopICorr;
    end
    
    if nStopIErrorCCorr > 0
        % Compute
        rtStopIErrorCCorr = sort(data.rt(iStopIErrorCCorr));
        
        % Log
        obs.rtStopIErrorCCorr{iTrialCat} = rtStopIErrorCCorr;
    end
    
    if nStopIErrorCError > 0
        % Compute
        rtStopIErrorCError = sort(data.rt(iStopIErrorCError));
      
        % Log
        obs.rtStopIErrorCError{iTrialCat} = rtStopIErrorCError;
    end
    
  end
  
  % Stop-signal delay
  % -----------------------------------------------------------------------
  if ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
    if numel(unique(nonnans(data.ssd(iSelect)))) > 1
      error('More than one SSD detected');
    end
    obs.ssd(iTrialCat)      = max([0,unique(nonnans(data.ssd(iSelect)))]);
  end

  % RT bin data
  % -----------------------------------------------------------------------
  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))
      
      if nGoCCorr > 0
          [obs.rtQGoCCorr{iTrialCat}, ...
           obs.cumProbGoCCorr{iTrialCat}, ...   
           obs.cumProbDefectiveGoCCorr{iTrialCat}, ...
           obs.probMassGoCCorr{iTrialCat}, ...
           obs.probMassDefectiveGoCCorr{iTrialCat}] = ...
           sam_bin_data(rtGoCCorr,pGoCCorr,cumProb,minBinSize);
      end
      
      if nGoCError > 0
          [obs.rtQGoCError{iTrialCat}, ...
           obs.cumProbGoCError{iTrialCat}, ...
           obs.cumProbDefectiveGoCError{iTrialCat}, ...
           obs.probMassGoCError{iTrialCat}, ...
           obs.probMassDefectiveGoCError{iTrialCat}] = ...
           sam_bin_data(rtGoCError,pGoCError,cumProb,minBinSize); 
      end
      
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
      
      if nStopICorr > 0
          
          obs.probMassStopICorr{iTrialCat} = 1;
          obs.probMassDefectiveStopICorr{iTrialCat} = pStopICorr;
          
      end
      
      if nStopIErrorCCorr > 0
          [obs.rtQStopIErrorCCorr{iTrialCat}, ...
           obs.cumProbStopIErrorCCorr{iTrialCat}, ...
           obs.cumProbDefectiveStopIErrorCCorr{iTrialCat}, ...
           obs.probMassStopIErrorCCorr{iTrialCat}, ...
           obs.probMassDefectiveStopIErrorCCorr{iTrialCat}] = ...
           sam_bin_data(rtStopIErrorCCorr,pStopIErrorCCorr,cumProb,minBinSize);
      end
      
      if nStopIErrorCError > 0
          [obs.rtQStopIErrorCError{iTrialCat}, ...
           obs.cumProbStopIErrorCError{iTrialCat}, ...
           obs.cumProbDefectiveStopIErrorCError{iTrialCat}, ...
           obs.probMassStopIErrorCError{iTrialCat}, ...
           obs.probMassDefectiveStopIErrorCError{iTrialCat}] = ...
           sam_bin_data(rtStopIErrorCError,pStopIErrorCError,cumProb,minBinSize);
      end
      
  end

  % Stimulus onsets and durations
  % -----------------------------------------------------------------------
  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))
    obs.onset{iTrialCat}    = blkdiag(trueM{:})*[stmOns(1) 0]';
    obs.duration{iTrialCat} = blkdiag(trueM{:})*[stmDur(1) 0]';
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
    obs.onset{iTrialCat}    = blkdiag(trueM{:})*[stmOns(1) stmOns(1) + obs.ssd(iTrialCat)]';
    obs.duration{iTrialCat} = blkdiag(trueM{:})*(stmDur)';
  end
  
end