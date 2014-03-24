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

qntls             = SAM.optim.cost.stat.cumProb;
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
% 5. CLASSIFY TRIALS, COMPUTE DESCRIPTIVES, AND SAVE DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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


for iTrialCat = 1:nTrialCat

  obs.trialCat{iTrialCat} = tagAll{iTrialCat};

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

  iSelectCorr   = intersect(iSelect, find(data.acc == 2));
  iSelectError  = intersect(iSelect,find(data.acc ~= 2));

  % Number of trials
  obs.nTotal(iTrialCat)   = numel(iSelect);
  obs.nCorr(iTrialCat)    = numel(iSelectCorr);
  obs.nError(iTrialCat)   = numel(iSelectError);

  % Probability
  obs.pCorr(iTrialCat)    = numel(iSelectCorr)./numel(iSelect);
  obs.pError(iTrialCat)   = numel(iSelectError)./numel(iSelect);

  % Response time
  obs.rtCorr{iTrialCat}   = sort(data.rt(iSelectCorr));
  obs.rtError{iTrialCat}  = sort(data.rt(iSelectError));

  if ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
    if numel(unique(nonnans(data.ssd(iSelect)))) > 1
      error('More than one SSD detected');
    end
    obs.ssd(iTrialCat)      = max([0,unique(nonnans(data.ssd(iSelect)))]);
  end


  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once')) && obs.nCorr(iTrialCat) > 0
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


  if ~isempty(regexp(tagAll{iTrialCat},'goTrial.*', 'once'))
    obs.onset{iTrialCat}    = blkdiag(trueM{:})*[stmOns(1) 0]';
    obs.duration{iTrialCat} = blkdiag(trueM{:})*[stmDur(1) 0]';
  elseif ~isempty(regexp(tagAll{iTrialCat},'stopTrial.*', 'once'))
    obs.onset{iTrialCat}    = blkdiag(trueM{:})*[stmOns(1) stmOns(1) + obs.ssd(iTrialCat)]';
    obs.duration{iTrialCat} = blkdiag(trueM{:})*[stmDur]';
  end

%     % 4.1.1. Compute timing diagram
%         % -----------------------------------------------------------------
%                                           % OUTPUT
%         [tStm, ...                        % - Time
%          uStm] ...                        % - Strength of stimulus (t)
%         = sam_spec_timing_diagram ...     % FUNCTION
%          ...                              % INPUT
%         (stimOns(:)', ...                 % - Stimulus onset time
%          stimDur(:)', ...                 % - Stimulus duration
%          [], ...                          % - Strength (default = 1);
%          0, ...                           % - Magnitude of extrinsic noise
%          dt, ...                          % - Time step
%          timeWindow);                     % - Time window

end