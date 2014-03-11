function varargout = sam_sim_expt(simGoal,X,SAM,varargin)
% Simulates response times and model dynamics for go and stop trials of the
% stop-signal task
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% prdOptimData = SAM_SIM_EXPT('optimize',X,SAM,prdOptimData); 
% [prd,modelMat] = SAM_SIM_EXPT('explore',X,SAM,prd); 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Sat 21 Sep 2013 12:54:52 CDT by bram 
% $Modified: Mon 23 Sep 2013 20:54:22 CDT by bramzandbelt

% CONTENTS 
% 1.PROCESS INPUTS AND SPECIFY VARIABLES
%   1.1.Process inputs
%   1.2.Specify static variables
%   1.3.Specify dynamic variables
%   1.4.Pre-allocate empty arrays
%       1.4.1.Trial numbers
%       1.4.2.Trial probabilities
%       1.4.3.Response times
%       1.4.4.Inhibition function
%       1.4.5.Structure of model matrices
% 2.DECODE PARAMETER VECTOR
% 3.SEED THE RANDOM NUMBER GENERATOR
% 4.SIMULATE EXPERIMENT
%   4.1.Specify timing diagram of stimuli
%   4.2.Specify timing diagram of model inputs
%   4.3.Simulate trials
%   4.4.Classify trials
%   4.5.Log model predictions
% 5.OUTPUT

% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% % 1. PROCESS INPUTS AND SPECIFY VARIABLES
% % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 
% % 1.1. Process inputs
% % ========================================================================= 
% 
% switch simGoal
%   case 'optimize'
%     prdOptimData = varargin{1};
%   case 'explore'
%     prd = varargin{1};
% end
% 
% % 1.1.1. Type of choice mechanism
% % -------------------------------------------------------------------------
% choiceMechType  = SAM.des.choiceMech.type;
% 
% % 1.1.2. Type of inhibition mechanism
% % -------------------------------------------------------------------------
% inhibMechType   = SAM.des.inhibMech.type;
% 
% % 1.1.3. Accumulation mechanism
% % -------------------------------------------------------------------------
% 
% % Lower bound on activation
% zLB           = SAM.des.accumMech.zLB;
% 
% % Time window during which accumulation is 'recorded'
% timeWindow    = SAM.des.accumMech.timeWindow;
% 
% % Time step
% dt            = SAM.des.time.dt;
% 
% % Time constant
% tau           = SAM.des.time.tau;
% 
% % Model parameters
% % -------------------------------------------------------------------------
% 
% % Parameter that varies across conditions
% condParam     = SAM.des.condParam;
% 
% % Number of GO and STOP units
% nGo           = SAM.des.nGO;
% nStop         = SAM.des.nSTOP;
% 
% durationSTOP  = SAM.des.durationSTOP;
% 
% % Simulator parameters
% % -------------------------------------------------------------------------
% simScope      = SAM.sim.scope;
% 
% nSim          = SAM.sim.nSim;
% 
% trialSimFun   = SAM.sim.trialSimFun;
% 
% % Experimental parameters
% % -------------------------------------------------------------------------
% 
% % Number of conditions
% nCnd          = SAM.des.expt.nCnd;
% 
% % Number of stop-signal delays
% nSsd          = SAM.des.expt.nSsd;
% 
% % Stimulus onsets
% stimOns       = SAM.des.expt.stimOns;
% 
% % Stimulus durations
% stimDur       = SAM.des.expt.stimDur;
% 
% 
% switch simGoal
%   case 'explore'
%     
%     % Time windows for alignment on go-signal
%     tWinGo    = SAM.explore.tWinGo;
%     
%     % Time windows for alignment on stop-signal
%     tWinStop  = SAM.explore.tWinStop;
%     
%     % Time windows for alignment on response
%     tWinResp  = SAM.explore.tWinGo;
% end
% 
% % 1.2. Specify static variables
% % =========================================================================
% 
switch simGoal
  case 'explore'
    % Cumulative probabilities for quantile averaging of model dynamics
    CUM_PROB = 0:0.01:1;
end
% 
% % 1.3. Specify dynamic variables
% % =========================================================================
% 
% switch lower(simScope)
%   case 'go'
%     % Number of units
%     N = nGo;
%     
%     % Number of model inputs (go and stop stimuli)
%     M = nGo;
%     
%     % Number of trial types: Go trials only
%     nTrType = 1;
%     
%     % Adjust stimulus onsets to include data from Go trials only
%     stimOns   = cellfun(@(a) a(1:M),stimOns,'Uni',0);
%     
%     % Adjust stimulus durations to include data from Go trials only
%     stimDur   = cellfun(@(a) a(1:M),stimDur,'Uni',0);
%     
%   case 'all'
%     % Number of units
%     N = [nGo nStop];
%     
%     % Number of model inputs (go and stop stimuli)
%     M = [nGo nStop];
%     
%     % Number of trial types: Go trials, and Stop trials with nSSD delays
%     nTrType = 1 + nSsd;
% end
% 
% % 1.4. Pre-allocate empty arrays
% % =========================================================================
% 
% % 1.4.1. Trial numbers
% % -------------------------------------------------------------------------
% nGoCorr         = nan(nCnd,1);         % Go correct
% nGoComm         = nan(nCnd,1);         % Go commission error
% nGoOmit         = nan(nCnd,1);         % Go omission error
% 
% switch lower(simScope)
%   case 'all'
%     nStopFailure  = nan(nCnd,nSsd);   % Stop failure
%     nStopSuccess  = nan(nCnd,nSsd);   % Stop success
% end
% 
% % 1.4.2. Trial probabilities
% % -------------------------------------------------------------------------
% pGoCorr         = nan(nCnd,1);         % Go correct
% pGoComm         = nan(nCnd,1);         % Go commission error
% pGoOmit         = nan(nCnd,1);         % Go omission error
% 
% switch lower(simScope)
%   case 'all'
%     pStopFailure  = nan(nCnd,nSsd);   % Stop failure
%     pStopSuccess  = nan(nCnd,nSsd);   % Stop success
% end
% 
% % 1.4.3. Response times
% % -------------------------------------------------------------------------
% rtGoCorr        = cell(nCnd,1);        % Go correct
% rtGoComm        = cell(nCnd,1);        % Go commission error
% 
% switch lower(simScope)
%   case 'all'
%     rtStopFailure = cell(nCnd,nSsd);  % Stop failure
%     rtStopSuccess = cell(nCnd,nSsd);  % Stop success
% end
% 
% % 1.4.4. Inhibition function
% % -------------------------------------------------------------------------
% switch lower(simScope)
%   case 'all'
%     inhibFunc     = cell(nCnd,1);
% end
% 
% % 1.4.5. Structure of model matrices
% % -------------------------------------------------------------------------
% switch simGoal
%   case 'explore'
%     modelMat = struct('A',[], ...     % Endogenous connectivity matrix
%                       'B',[], ...     % Extrinsic modulation matrix
%                       'C',[], ...     % Exogenous connectivity matrix
%                       'D',[], ...     % Intrinsic modulation matrix
%                       'V',[], ...     % Accumulation rate matrix
%                       'SE',[], ...    % Extrinsic noise matrix
%                       'SI',[], ...    % Intrinsic noise matrix
%                       'Z0',[], ...    % Starting value matrix
%                       'ZC',[], ...    % Threshold matrix
%                       'zLB',[], ...   % Lower bound on activation
%                       'accumOns',[], ... % Accumulation onset times
%                       'terminate',[], ... % Termination matrix
%                       'blockInput',[], ... % Blocked input matrix
%                       'latInhib',[]);       % Lateral inhibition matrix
%                     
% end
% 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Process inputs
% ========================================================================= 

nTrialCat     = size(SAM.optim.obs,1);

% 1.1.1. Experiment variables
% -------------------------------------------------------------------------------------------------------------------------

N             = SAM.expt.nRsp;
trialDur      = SAM.expt.trialDur;

nRsp          = SAM.expt.nRsp;
nStm          = SAM.expt.nStm;
i1            = [1,cumsum(nRsp(1:end-1)) + 1];          % Index of first response alternative, per class
iEnd          = cumsum(nRsp);                           % Index of last response alternative, per class
iRsp          = arrayfun(@(a,b) a:b,i1,iEnd,'Uni',0);   % Indices of all response alternatives, per class


% 1.1.2. Model variables
% -------------------------------------------------------------------------------------------------------------------------

terminate     = SAM.model.mat.terminate;
blockInput    = SAM.model.mat.interClassBlockInp;
latInhib      = SAM.model.mat.interClassLatInhib;


dt            = SAM.model.accum.dt;
timeWindow    = SAM.model.accum.window;
zLB           = SAM.model.accum.zLB;
tau           = SAM.model.accum.tau;
accumTWindow  = SAM.model.accum.window;


signatureGo   = any(SAM.model.variants.toFit.features(:,:,1),2);
signatureStop = any(SAM.model.variants.toFit.features(:,:,2),2);

% We can control the random variability in starting point, non-decision time, and accumulation rate
if SAM.model.accum.randomZ0
  randomZ0Factor = 1;
else
  randomZ0Factor = realmin;
end

if SAM.model.accum.randomT0
  randomT0Factor = 1;
else
  randomT0Factor = realmin;
end

T       = (accumTWindow(1):dt:accumTWindow(2))';
p   = length(T);
t1  = 1;                    % First time point

% 1.1.3. Simulation variables
% -------------------------------------------------------------------------------------------------------------------------
nSim          = SAM.sim.n;
trialSimFun   = SAM.sim.fun.trial;
alignTWindow  = SAM.sim.tWindow;
rngSeedStage  = SAM.sim.rng.stage;
rngSeedId     = SAM.sim.rng.id;


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. SEED THE RANDOM NUMBER GENERATOR (OPTIONAL)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch lower(rngSeedStage)
  case 'sam_sim_expt'

    % Note: MEX functions stay in memory until they are cleared.
    % Seeding of the random number generator should be accompanied by 
    % clearing MEX functions.

    clear(char(trialSimFun));
    rng(rngSeedId);
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. SIMULATE EXPERIMEMT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Loop over trial categories
for iTrialCat = 1:nTrialCat
  
  trialCat    = SAM.optim.obs.trialCat{iTrialCat};
  stmOns      = SAM.optim.obs.onset{iTrialCat};
  stmDur      = SAM.optim.obs.duration{iTrialCat};
  
  iTargetGO       = find(SAM.optim.modelMat.iTarget{iTrialCat}{1});
  iNonTargetGO    = find(SAM.optim.modelMat.iNonTarget{iTrialCat}{1});
  iGO             = sort([iTargetGO(:);iNonTargetGO(:)]);
  iTargetSTOP     = find(SAM.optim.modelMat.iTarget{iTrialCat}{2});
  iNonTargetSTOP  = find(SAM.optim.modelMat.iNonTarget{iTrialCat}{2});
  iSTOP           = sort([iTargetSTOP(:);iNonTargetSTOP(:)]);
  
  % Pre-allocate response time and response arrays
  rt  = inf(sum(N),nSim);
  
  switch simGoal
    case 'explore'
      z = nan(sum(nRsp),nSim,p);
      uLog = nan(sum(nStm),nSim,p);
  end
  
  % 3.1. Decode parameter vector
  % =====================================================================
  [endoConn, ...
   extrMod, ...
   exoConn, ...
   intrMod, ...
   V, ...
   SE, ...
   SI, ...
   Z0, ...
   ZC, ...
   T0] ...
   ...
   = sam_decode_x( ...
   ...
   SAM, ...
   X, ...
   iTrialCat);
  
  
  
  n   = size(endoConn,1);     % Number of units
  m   = size(exoConn,2);      % Number of inputs to units
  ZLB = zLB*ones(n,1);
  
  % 3.2. Simulate trials
  % =====================================================================
  for iTr = 1:nSim
%   parfor iTr = 1:nSim

    % 3.2.1. Timing diagram of model inputs
    % -----------------------------------------------------------------------------------------------------------------

    accumOns = stmOns(:)' + T0(:)' - T0(:)'.*randomT0Factor.*rand(1,m);

    if ~isempty(regexp(trialCat,'stopTrial.*', 'once'))
      switch lower(SAM.accum.durSTOP)
        case 'signal'
          accumDur = stmDur(:)';
        case 'trial'
          accumDur = stmDur(:)';
          accumDur(iRsp{2}) = trialDur - accumOns(iRsp{2});
        otherwise
          accumDur = stmDur(:)';
      end
    else
      accumDur = stmDur(:)';
    end

    [t, ...                               % - Time
     u] ...                               % - Strength of model input
    = sam_spec_timing_diagram ...         % FUNCTION
    ...                                   % INPUT
    (accumOns, ...                        % - Accumulation onset time
     accumDur, ...                        % - Stimulus duration
     V, ...                               % - Input strength
     SE, ...                              % - Magnitude of extrinsic noise
     dt, ...                              % - Time step
     timeWindow);                         % - Time window

    t = t(:)';

    % 3.2.2. Simulate trials
    % -----------------------------------------------------------------------------------------------------------------

    switch simGoal
      case 'optimize'
        rt(:,iTr) ...                  % - Response time
        =  feval ...                   % FUNCTION
        ...                            % INPUT
        (trialSimFun, ...               % - Function handle
        u, ...                         % - Timing diagram of model inputs
        endoConn, ...                  % - Endogenous connectivity matrix
        extrMod, ...                   % - Extrinsic modulation matrix
        exoConn, ...                   % - Exogenous connectivity matrix
        intrMod, ...                   % - Intrinsic modulation matrix
        SI, ...                        % - Intrinsic noise matrix
        Z0 - (Z0-zLB).*randomZ0Factor.*rand(n,1), ...                        % - Starting point matrix
        ZC, ...                        % - Threshold matrix
        ZLB, ...                       % - Activation lower bound matrix
        dt, ...                        % - Time step
        tau, ...                       % - Time scale
        t, ...                         % - Time points
        terminate, ...                 % - Termination matrix
        blockInput, ...                % - Blocked input matrix
        latInhib, ...                  % - Lateral inhibition matrix
        n, ...                         % - Number of units
        m, ...                         % - Number of inputs
        p, ...                         % - Number of time points
        t1, ...                        % - First time index
        inf(n,1), ...                  % - Array for current trial's RT
        false(n,1), ...                % - Array for current trial's response
        nan(n,p));                     % - Array for current trial's dynamics)
      
      case 'explore'
        
        [rt(:,iTr), ...                  % - Response time
         ~, ...                         % - Responses
         z(:,iTr,:)] ...                % - Dynamics  
        ...
        =  feval ...                   % FUNCTION
        ...                            % INPUT
        (trialSimFun, ...               % - Function handle
        u, ...                         % - Timing diagram of model inputs
        endoConn, ...                  % - Endogenous connectivity matrix
        extrMod, ...                   % - Extrinsic modulation matrix
        exoConn, ...                   % - Exogenous connectivity matrix
        intrMod, ...                   % - Intrinsic modulation matrix
        SI, ...                        % - Intrinsic noise matrix
        Z0 - (Z0-zLB).*randomZ0Factor.*rand(n,1), ...                        % - Starting point matrix
        ZC, ...                        % - Threshold matrix
        ZLB, ...                       % - Activation lower bound matrix
        dt, ...                        % - Time step
        tau, ...                       % - Time scale
        t, ...                         % - Time points
        terminate, ...                 % - Termination matrix
        blockInput, ...                % - Blocked input matrix
        latInhib, ...                  % - Lateral inhibition matrix
        n, ...                         % - Number of units
        m, ...                         % - Number of inputs
        p, ...                         % - Number of time points
        t1, ...                        % - First time index
        inf(n,1), ...                  % - Array for current trial's RT
        false(n,1), ...                % - Array for current trial's response
        nan(n,p));                     % - Array for current trial's dynamics)
      
        uLog(:,iTr,:) = u;
    end
  end
    
  % 3.4. Classify trials
  % =====================================================================
  
  if ~isempty(regexp(trialCat,'goTrial.*', 'once'))
    
    % 4.4.1. Go correct trial: only one RT, produced by target GO unit
    % -------------------------------------------------------------------
    % Criteria (all should be met):
    % - Target GO unit produced an RT
    % - Target GO unit is the only unit having produced an RT
    iCorr = rt(iTargetGO,:) < Inf & sum(rt < Inf) == 1;
    
    % 4.4.2. Go commission error trial: any RT produced by a non-target GO unit
    % -------------------------------------------------------------------
    % Criteria (all should be met):
    % - At least one non-target GO unit has produced an RT
    iError = any(rt(iNonTargetGO,:) < Inf,1);

    % 4.4.3. Go omission error trial: no RT
    % -------------------------------------------------------------------
    % Criteria (all should be met):
    % - No unit has produced an RT
    iOmit = sum(rt < Inf) == 0;

  elseif ~isempty(regexp(trialCat,'stopTrial.*', 'once'))
    
    if all(SAM.model.mat.endoConn.nonSelfOther == 0) % GO and STOP race
      % Stop success trial
      % -------------------------------------------------------------------
      % Criteria (*any* should be met)
      % - STOP unit produces a shorter RT than any other GO units
      % - None of the units produced an RT
      iCorr = rt(iTargetSTOP,:) < min(rt(iGO,:),[],1) | all(rt == Inf);
      
      % Stop failure trial
      % -------------------------------------------------------------------
      % Criteria
      % - The fastest GO unit has a shorter RT than any STOP unit
      iError = min(rt(iGO,:),[],1) < rt(iSTOP,:);
      
      % Note: no distinction made between correct and error choice in
      % Go task
      
      iOmit = [];
    else
      % Stop success trial
      % -------------------------------------------------------------------
      % Criteria (all should be met):
      % - None of the GO units produced an RT
      iCorr = all(rt(iGO,:) == Inf);
      
      % Note: no distinction made between trials in which the STOP unit
      % did and did not produce and RT. We may be more stringent,
      % requiring that STOP finishes, or we could look at how
      % computation of SSRT is influenced by including trials in which
      % STOP did not finish versus when these trials are not included.
      
      % Stop failure trial
      % -------------------------------------------------------------------
      % Criteria:
      % - At least one GO unit has produced an RT
      iError = any(rt(iGO,:) < Inf);

      % Note: no distinction made between correct and error choice in
      % Go task

      % Note: no distinction made between trials in which the STOP unit
      % did and did not produce an RT (i.e. STOP units cannot terminate
      % the trial under 'blocked input' and 'lateral inhibition'
      % inhibition mechanisms)
      
      iOmit = [];
    end
    
  end
  
  % 3.5. Log model predictions
  % =====================================================================

  % 3.5.1. Trial numbers
  % ---------------------------------------------------------------------
  
  % Compute
  nCorr = numel(find(iCorr));
  nError = numel(find(iError));
  nOmit = numel(find(iOmit));
  
  % Log
  prd.nTotal(iTrialCat) = nCorr + nError + nOmit;
  prd.nCorr(iTrialCat) = nCorr;
  prd.nError(iTrialCat) = nError;
  prd.nOmit(iTrialCat) = nOmit;
  
  
  % 3.5.2. Trial probabilities
  % ---------------------------------------------------------------------
  
  % Compute
  pCorr = nCorr./nSim;
  pError = nError./nSim;
  pOmit = nOmit./nSim;
  
  % Log
  prd.pTotal(iTrialCat) = pCorr + pError + pOmit;
  prd.pCorr(iTrialCat) = pCorr;
  prd.pError(iTrialCat) = pError;
  prd.pOmit(iTrialCat) = pOmit;
  
  % 3.5.3. Trial response times
  % ---------------------------------------------------------------------
  if ~isempty(regexp(trialCat,'goTrial.*', 'once'))
    if nCorr > 0
      rtCorr = sort(rt(iTargetGO,iCorr)) - stmOns(iTargetGO);
      
      prd.rtCorr{iTrialCat} = rtCorr;
    end
    
    if nError > 0
      rtError = sort(min(rt(iNonTargetGO,iError),[],1)) - stmOns(iTargetGO);
      
      % Note: stimOns for iTargetGO and iNonTargetGO are the same; I use iTargetGO instead
      % of iNonTargetGO because iTargetGO is always a scalar, iNonTargetGO not.
      
      prd.rtError{iTrialCat} = rtError;
    end
    
  elseif ~isempty(regexp(trialCat,'stopTrial.*', 'once'))
    if nCorr > 0
      rtCorr = sort(rt(iSTOP,iCorr)) - stmOns(iSTOP);
      
      prd.rtCorr{iTrialCat} = rtCorr;
    end
    
    if nError > 0
      rtError = sort(min(rt(iGO,iError),[],1)) - stmOns(iTargetGO);
      
      prd.rtError{iTrialCat} = rtError;
    end
    
  end
  
  % 3.5.4. Model dynamics
  % ---------------------------------------------------------------------
  switch simGoal
    case 'explore'
      if ~isempty(regexp(trialCat,'goTrial.*', 'once'))
        
        % Go correct quantile averaged dynamics
        if nCorr >= 1

          % Randomly sample one non-target GO unit
          thisINonTargetGO = randsample([iNonTargetGO(:);iNonTargetGO(:)],1);  % N.B. Repeating iNonTargetGO prevents that iNonTargetGO is a scalar, under which randsample samples from 1:iNonTargetGO

          % Get event times of go-signals and correct responses  
          etGo = repmat(stmOns(iTargetGO),nCorr,1);
          etResp = rt(iTargetGO,iCorr);

          % Get quantile averaged dynamics of targetGO aligned on go-signal
          [prd.dyn{iTrialCat}.corr.goStim.targetGO.qX, ...
           prd.dyn{iTrialCat}.corr.goStim.targetGO.qY, ...
           prd.dyn{iTrialCat}.corr.goStim.targetGO.sX, ...
           prd.dyn{iTrialCat}.corr.goStim.targetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,iTargetGO,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of nonTargetGO aligned on go-signal
          [prd.dyn{iTrialCat}.corr.goStim.nonTargetGO.qX, ...
           prd.dyn{iTrialCat}.corr.goStim.nonTargetGO.qY, ...
           prd.dyn{iTrialCat}.corr.goStim.nonTargetGO.sX, ...
           prd.dyn{iTrialCat}.corr.goStim.nonTargetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,thisINonTargetGO,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of targetGO aligned on response
          [prd.dyn{iTrialCat}.corr.resp.targetGO.qX, ...
           prd.dyn{iTrialCat}.corr.resp.targetGO.qY, ...
           prd.dyn{iTrialCat}.corr.resp.targetGO.sX, ...
           prd.dyn{iTrialCat}.corr.resp.targetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,iTargetGO,etResp,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of nonTargetGO aligned on response
          [prd.dyn{iTrialCat}.corr.resp.nonTargetGO.qX, ...
           prd.dyn{iTrialCat}.corr.resp.nonTargetGO.qY, ...
           prd.dyn{iTrialCat}.corr.resp.nonTargetGO.sX, ...
           prd.dyn{iTrialCat}.corr.resp.nonTargetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,thisINonTargetGO,etResp,CUM_PROB,alignTWindow.go);
        end

        if nError >= 1

          % Get event times of go-signals and error responses  
          etGo = repmat(stmOns(iTargetGO),nError,1);
          [etResp,iNonTargetGOError]   = min(rt(:,iError),[],1);

          % Get quantile averaged dynamics of target GO aligned on go-signal
          [prd.dyn{iTrialCat}.error.goStim.targetGO.qX, ...
           prd.dyn{iTrialCat}.error.goStim.targetGO.qY, ...
           prd.dyn{iTrialCat}.error.goStim.targetGO.sX, ...
           prd.dyn{iTrialCat}.error.goStim.targetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iTargetGO,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of error nontarget GO aligned on go-signal
          [prd.dyn{iTrialCat}.error.goStim.nonTargetGOError.qX, ...
           prd.dyn{iTrialCat}.error.goStim.nonTargetGOError.qY, ...
           prd.dyn{iTrialCat}.error.goStim.nonTargetGOError.sX, ...
           prd.dyn{iTrialCat}.error.goStim.nonTargetGOError.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iNonTargetGOError,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of target GO aligned on response
          [prd.dyn{iTrialCat}.error.resp.targetGO.qX, ...
           prd.dyn{iTrialCat}.error.resp.targetGO.qY, ...
           prd.dyn{iTrialCat}.error.resp.targetGO.sX, ...
           prd.dyn{iTrialCat}.error.resp.targetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iTargetGO,etResp,CUM_PROB,alignTWindow.resp);

          % Get quantile averaged dynamics of error nontarget GO aligned on go-signal
          [prd.dyn{iTrialCat}.error.resp.nonTargetGOError.qX, ...
           prd.dyn{iTrialCat}.error.resp.nonTargetGOError.qY, ...
           prd.dyn{iTrialCat}.error.resp.nonTargetGOError.sX, ...
           prd.dyn{iTrialCat}.error.resp.nonTargetGOError.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iNonTargetGOError,etResp,CUM_PROB,alignTWindow.resp);
        end
        
      elseif ~isempty(regexp(trialCat,'stopTrial.*', 'once'))
        
        if nError >= 1 % Stop failure trial

          % Get event times of go-signals, stop-signals and error responses  
          etGo = repmat(stmOns(iTargetGO),nError,1);
          etStop = repmat(stmOns(iTargetSTOP),nError,1);
          [etResp,iRespGO]   = min(rt(iGO,iError),[],1);
          iRespGO = iGO(iRespGO);

          % Get quantile averaged dynamics of respGO aligned on go-signal
          [prd.dyn{iTrialCat}.error.goStim.respGO.qX, ...
           prd.dyn{iTrialCat}.error.goStim.respGO.qY, ...
           prd.dyn{iTrialCat}.error.goStim.respGO.sX, ...
           prd.dyn{iTrialCat}.error.goStim.respGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iRespGO,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of targetSTOP aligned on go-signal
          [prd.dyn{iTrialCat}.error.goStim.targetSTOP.qX, ...
           prd.dyn{iTrialCat}.error.goStim.targetSTOP.qY, ...
           prd.dyn{iTrialCat}.error.goStim.targetSTOP.sX, ...
           prd.dyn{iTrialCat}.error.goStim.targetSTOP.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iTargetSTOP,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of respGO aligned on stop-signal
          [prd.dyn{iTrialCat}.error.stopStim.respGO.qX, ...
           prd.dyn{iTrialCat}.error.stopStim.respGO.qY, ...
           prd.dyn{iTrialCat}.error.stopStim.respGO.sX, ...
           prd.dyn{iTrialCat}.error.stopStim.respGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iRespGO,etStop,CUM_PROB,alignTWindow.stop);

          % Get quantile averaged dynamics of targetSTOP aligned on stop-signal
          [prd.dyn{iTrialCat}.error.stopStim.targetSTOP.qX, ...
           prd.dyn{iTrialCat}.error.stopStim.targetSTOP.qY, ...
           prd.dyn{iTrialCat}.error.stopStim.targetSTOP.sX, ...
           prd.dyn{iTrialCat}.error.stopStim.targetSTOP.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iTargetSTOP,etStop,CUM_PROB,alignTWindow.stop);

          % Get quantile averaged dynamics of respGO aligned on response
          [prd.dyn{iTrialCat}.error.resp.respGO.qX, ...
           prd.dyn{iTrialCat}.error.resp.respGO.qY, ...
           prd.dyn{iTrialCat}.error.resp.respGO.sX, ...
           prd.dyn{iTrialCat}.error.resp.respGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iRespGO,etResp,CUM_PROB,alignTWindow.resp);

          % Get quantile averaged dynamics of targetSTOP aligned on response
          [prd.dyn{iTrialCat}.error.resp.targetSTOP.qX, ...
           prd.dyn{iTrialCat}.error.resp.targetSTOP.qY, ...
           prd.dyn{iTrialCat}.error.resp.targetSTOP.sX, ...
           prd.dyn{iTrialCat}.error.resp.targetSTOP.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iError,iTargetSTOP,etResp,CUM_PROB,alignTWindow.resp);

        end

        if nCorr >= 1

          % Get event times of go-signals and stop-signals
          etGo = repmat(stmOns(iTargetGO),nCorr,1);
          etStop = repmat(stmOns(iTargetSTOP),nCorr,1);

          % Get quantile averaged dynamics of target GO aligned on go-signal
          [prd.dyn{iTrialCat}.corr.goStim.targetGO.qX, ...
           prd.dyn{iTrialCat}.corr.goStim.targetGO.qY, ...
           prd.dyn{iTrialCat}.corr.goStim.targetGO.sX, ...
           prd.dyn{iTrialCat}.corr.goStim.targetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,iTargetGO,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of target STOP aligned on go-signal
          [prd.dyn{iTrialCat}.corr.goStim.targetSTOP.qX, ...
           prd.dyn{iTrialCat}.corr.goStim.targetSTOP.qY, ...
           prd.dyn{iTrialCat}.corr.goStim.targetSTOP.sX, ...
           prd.dyn{iTrialCat}.corr.goStim.targetSTOP.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,iTargetSTOP,etGo,CUM_PROB,alignTWindow.go);

          % Get quantile averaged dynamics of target GO aligned on stop-signal
          [prd.dyn{iTrialCat}.corr.stopStim.targetGO.qX, ...
           prd.dyn{iTrialCat}.corr.stopStim.targetGO.qY, ...
           prd.dyn{iTrialCat}.corr.stopStim.targetGO.sX, ...
           prd.dyn{iTrialCat}.corr.stopStim.targetGO.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,iTargetGO,etStop,CUM_PROB,alignTWindow.stop);

          % Get quantile averaged dynamics of target STOP aligned on stop-signal
          [prd.dyn{iTrialCat}.corr.stopStim.targetSTOP.qX, ...
           prd.dyn{iTrialCat}.corr.stopStim.targetSTOP.qY, ...
           prd.dyn{iTrialCat}.corr.stopStim.targetSTOP.sX, ...
           prd.dyn{iTrialCat}.corr.stopStim.targetSTOP.sY] ...
          = sam_get_dynamics('qav-sample100',T,z,iCorr,iTargetSTOP,etStop,CUM_PROB,alignTWindow.stop);

        end
      end
  end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. OUTPUT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch simGoal
  case 'optimize'
    
    % Make one array of trial probabilities and response times
    switch lower(simScope)
      case 'go'
        prdOptimData.P       = [pCorr,pError];
        prdOptimData.rt      = [rtCorr,rtError];
      case 'all'
        prdOptimData.P       = [pCorr,pGoComm,pStopFailure];
        prdOptimData.rt      = [rtGoCorr,rtGoComm,rtStopFailure];
    end
    
    % Specify output
    varargout{1} = prdOptimData;
    
  case 'explore'
    
    
    % Place trial probabilities, response times, and inhibition function in
    % dataset array
    prd.pGoCorr           = pGoCorr;
    prd.pGoComm           = pGoComm;
    prd.pGoOmit           = pGoOmit;
    
    prd.rtGoCorr          = rtGoCorr;
    prd.rtGoComm          = rtGoComm;
    
    switch lower(simScope)
      case 'all'
        
        prd.pStopFailure  = pStopFailure;
        prd.pStopSuccess  = pStopSuccess;
        prd.inhibFunc     = inhibFunc;
        
        prd.rtStopFailure = rtStopFailure;
        prd.rtStopSuccess = rtStopSuccess;
        
    end
    
    % Make a struct of model matrices that were used in the simulations
    modelMat.A = A;
    modelMat.B = B;
    modelMat.C = C;
    modelMat.D = D;
    modelMat.V = V;
    modelMat.SE = SE;
    modelMat.SI = SI;
    modelMat.Z0 = Z0;
    modelMat.ZC = ZC;
    modelMat.ZLB = ZLB;
%     modelMat.accumOns = accumOns;
    modelMat.terminate = terminate;
    modelMat.blockInput = blockInput;
    modelMat.latInhib = latInhib;
        
    % Specify output
    varargout{1} = prd;
    varargout{2} = modelMat;
end