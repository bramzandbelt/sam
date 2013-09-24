function varargout = sam_sim_expt(simGoal,X,SAM,VCor,VIncor,S,terminate,blockInput,latInhib,varargin)
% Simulates response times and model dynamics for go and stop trials of the
% stop-signal task
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% prdOptimData = SAM_SIM_EXPT('optimize',X,SAM,VCor,VIncor,S,terminate,blockInput,latInhib,prdOptimData); 
% [prd,modelMat] = SAM_SIM_EXPT('explore',X,SAM,VCor,VIncor,S,terminate,blockInput,latInhib,prd); 
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
% 3.SIMULATE EXPERIMENT
%   3.1.Specify timing diagram of stimuli
%   3.2.Specify timing diagram of model inputs
%   3.3.Simulate trials
%   3.4.Classify trials
%   3.5.Log model predictions
% 4.OUTPUT

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Process inputs
% ========================================================================= 

switch simGoal
  case 'optimize'
    prdOptimData = varargin{1};
  case 'explore'
    prd = varargin{1};
end

% 1.1.1. Type of choice mechanism
% -------------------------------------------------------------------------
choiceMechType  = SAM.des.choiceMech.type;

% 1.1.2. Type of inhibition mechanism
% -------------------------------------------------------------------------
inhibMechType   = SAM.des.inhibMech.type;

% 1.1.3. Accumulation mechanism
% -------------------------------------------------------------------------

% Lower bound on activation
zLB         = SAM.des.accumMech.zLB;

% Time window during which accumulation is 'recorded'
timeWindow  = SAM.des.accumMech.timeWindow;

% Time step
dt          = SAM.des.time.dt;

% Time constant
tau         = SAM.des.time.tau;

% Model parameters
% -------------------------------------------------------------------------

% Parameter that varies across conditions
condParam   = SAM.des.condParam;

% Number of GO and STOP units
nGo         = SAM.des.nGO;
nStop       = SAM.des.nSTOP;

% Simulator parameters
% -------------------------------------------------------------------------
simScope    = SAM.sim.scope;

nSim        = SAM.sim.nSim;

trialSimFun = SAM.sim.trialSimFun;

% Experimental parameters
% -------------------------------------------------------------------------

% Number of conditions
nCnd        = SAM.des.expt.nCnd;

% Number of stop-signal delays
nSsd        = SAM.des.expt.nSsd;

% Stimulus onsets
stimOns     = SAM.des.expt.stimOns;

% Stimulus durations
stimDur     = SAM.des.expt.stimDur;


switch simGoal
  case 'explore'
    
    % Time windows for alignment on go-signal
    tWinGo  = SAM.explore.tWinGo;
    
    % Time windows for alignment on stop-signal
    tWinStop  = SAM.explore.tWinStop;
    
    % Time windows for alignment on response
    tWinResp  = SAM.explore.tWinGo;
end

% 1.2. Specify static variables
% =========================================================================

switch simGoal
  case 'explore'
    % Cumulative probabilities for quantile averaging of model dynamics
    CUM_PROB = 0:0.01:1;
end

% 1.3. Specify dynamic variables
% =========================================================================

switch lower(simScope)
  case 'go'
    % Number of units
    N = nGo;
    
    % Number of model inputs (go and stop stimuli)
    M = nGo;
    
    % Number of trial types: Go trials only
        
  case 'all'
    % Number of units
    N = [nGo nStop];
    
    % Number of model inputs (go and stop stimuli)
    M = [nGo nStop];
    
    % Number of trial types: Go trials, and Stop trials with nSSD delays
    nTrType = 1 + nSsd;
end

% 1.4. Pre-allocate empty arrays
% =========================================================================

% 1.4.1. Trial numbers
% -------------------------------------------------------------------------
nGoCorr         = nan(nCnd,1);         % Go correct
nGoComm         = nan(nCnd,1);         % Go commission error
nGoOmit         = nan(nCnd,1);         % Go omission error

switch lower(simScope)
  case 'all'
    nStopFailure  = nan(nCnd,nSsd);   % Stop failure
    nStopSuccess  = nan(nCnd,nSsd);   % Stop success
end

% 1.4.2. Trial probabilities
% -------------------------------------------------------------------------
pGoCorr         = nan(nCnd,1);         % Go correct
pGoComm         = nan(nCnd,1);         % Go commission error
pGoOmit         = nan(nCnd,1);         % Go omission error

switch lower(simScope)
  case 'all'
    pStopFailure  = nan(nCnd,nSsd);   % Stop failure
    pStopSuccess  = nan(nCnd,nSsd);   % Stop success
end

% 1.4.3. Response times
% -------------------------------------------------------------------------
rtGoCorr        = cell(nCnd,1);        % Go correct
rtGoComm        = cell(nCnd,1);        % Go commission error

switch lower(simScope)
  case 'all'
    rtStopFailure = cell(nCnd,nSsd);  % Stop failure
    rtStopSuccess = cell(nCnd,nSsd);  % Stop success
end

% 1.4.4. Inhibition function
% -------------------------------------------------------------------------
switch lower(simScope)
  case 'all'
    inhibFunc     = cell(nCnd,1);
end

% 1.4.5. Structure of model matrices
% -------------------------------------------------------------------------
switch simGoal
  case 'explore'
    modelMat = struct('A',[], ...     % Endogenous connectivity matrix
                      'B',[], ...     % Extrinsic modulation matrix
                      'C',[], ...     % Exogenous connectivity matrix
                      'D',[], ...     % Intrinsic modulation matrix
                      'V',[], ...     % Accumulation rate matrix
                      'SE',[], ...    % Extrinsic noise matrix
                      'SI',[], ...    % Intrinsic noise matrix
                      'Z0',[], ...    % Starting value matrix
                      'ZC',[], ...    % Threshold matrix
                      'zLB',[], ...   % Lower bound on activation
                      'accumOns',[], ... % Accumulation onset times
                      'terminate',[], ... % Termination matrix
                      'blockInput',[], ... % Blocked input matrix
                      'latInhib',[]);       % Lateral inhibition matrix
                    
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. DECODE PARAMETER VECTOR
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

                              % OUTPUTS
[A, ...                       % Endogenous connectivity matrix
 B, ...                       % Extrinsic modulation matrix
 C, ...                       % Exogenous connectivity matrix
 D, ...                       % Intrinsic modulation matrix
 V, ...                       % Accumulation rate matrix
 SE, ...                      % Extrinsic noise matrix
 SI, ...                      % Extrinsic noise matrix
 Z0, ...                      % Starting value matrix
 ZC, ...                      % Threshold matrix
 accumOns] ...                % Accumulation onset times
 ...
 = sam_decode_x( ...          % FUNCTION
 ...                          % INPUTS
 X, ...                       % Parameter vector
 choiceMechType, ...          % Choice mechanism
 inhibMechType, ...           % Inhibition mechanism
 condParam, ...               % Parameter varying across task conditions
 simScope, ...                % Scope of simulation
 stimOns, ...                 % Stimulus onsets
 stimDur, ...                 % Stimulus durations
 N, ...                       % Number of model units (per accumulator class)
 M, ...                       % Number of model inputs (per accumulator class)
 VCor, ...                    % Precursor matrix for correct rates
 VIncor, ...                  % Precursor matrix for error rates
 S);                          % Precursor matrix for noise

% Lower bound on activation
ZLB = zLB*ones(sum(N),1);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. SIMULATE EXPERIMEMT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Loop over task conditions                 
for iCnd = 1:nCnd
  
  % Get unit indices for this task condition
  iGO   = SAM.des.iGO{iCnd};
  iGOT  = SAM.des.iGOT{iCnd};
  iGONT = SAM.des.iGONT{iCnd};
  iSTOP = SAM.des.iSTOP{iCnd};
  
  % Loop over trial types
  for iTrType = 1:nTrType
    
    % 3.1. Specify timing diagram of stimuli
    % =====================================================================
    switch simGoal
      case 'explore'
        
        % 3.1.1. Compute timing diagram
        % -----------------------------------------------------------------
                                          % OUTPUT
        [tStm, ...                        % - Time
         uStm] ...                        % - Strength of stimulus (t)
        = sam_spec_timing_diagram ...     % FUNCTION
         ...                              % INPUT
        (stimOns{iCnd,iTrType}(:)', ...   % - Stimulus onset time
         stimDur{iCnd,iTrType}(:)', ...   % - Stimulus duration
         [], ...                          % - Strength (default = 1);
         0, ...                           % - Magnitude of extrinsic noise
         dt, ...                          % - Time step
         timeWindow);                     % - Time window
        
       % 3.1.2. Log timing diagram
       % ------------------------------------------------------------------
       
        if iTrType == 1
          prd.tDiagram{iCnd,iTrType}.stim.go.X = tStm;
          prd.tDiagram{iCnd,iTrType}.stim.go.Y = uStm;
        elseif iTrType > 1
          prd.tDiagram{iCnd,iTrType}.stim.stop.X = tStm;
          prd.tDiagram{iCnd,iTrType}.stim.stop.Y = uStm;
        end
    end
    
    % 3.2. Timing diagram of model inputs
    % =====================================================================
      
    % 3.2.1. Compute timing diagram
    % ---------------------------------------------------------------------
                                          % OUTPUT
    [t, ...                               % - Time
     u] ...                               % - Strength of model input
     = sam_spec_timing_diagram ...        % FUNCTION
     ...                                  % INPUT
    (accumOns{iCnd,iTrType}(:)', ...      % - Accumulation onset time
     stimDur{iCnd,iTrType}(:)', ...       % - Stimulus duration
     V{iCnd,iTrType}, ...                 % - Input strength
     SE{iCnd,iTrType}, ...                % - Magnitude of extrinsic noise
     dt, ...                              % - Time step
     timeWindow);                         % - Time window
    
    % 3.2.2. Log timing diagram
    % ---------------------------------------------------------------------
    switch simGoal
      case 'explore'
        if iTrType == 1
          prd.tDiagram{iCnd,iTrType}.modelinput.go.X = t;
          prd.tDiagram{iCnd,iTrType}.modelinput.go.Y = u;
        elseif iTrType > 1
          prd.tDiagram{iCnd,iTrType}.modelinput.stop.X = t;
          prd.tDiagram{iCnd,iTrType}.modelinput.stop.Y = u;
        end
    end
    
    % 3.3. Simulate trials
    % =====================================================================
    
    % Pre-allocate response time and response arrays
    rt = inf(sum(N),nSim);
    
    switch simGoal
      case 'optimize'
        
        % Getting rid of indexing (and using feval) reduces overhead of
        % parfor loops
        thisSI = diag(SI{iCnd,iTrType});
        thisZC = ZC{iCnd};
        thisT  = t(:)';
        
        % Loop over trials
        parfor iTr = 1:nSim
                                          % OUTPUT                          
           rt(:,iTr) ...                  % - Response time
           =  feval ...                   % FUNCTION
           ...                            % INPUT
          (trialSimFun, ...               % - Function handle
           u, ...                         % - Timing diagram of model inputs
           A, ...                         % - Endogenous connectivity matrix
           B, ...                         % - Extrinsic modulation matrix
           C, ...                         % - Exogenous connectivity matrix
           D, ...                         % - Intrinsic modulation matrix
           thisSI, ...                    % - Intrinsic noise matrix
           Z0, ...                        % - Starting point matrix
           thisZC, ...                    % - Threshold matrix
           ZLB, ...                       % - Activation lower bound matrix
           dt, ...                        % - Time step
           tau, ...                       % - Time scale
           thisT, ...                     % - Time points
           terminate, ...                 % - Termination matrix
           blockInput, ...                % - Blocked input matrix
           latInhib);                     % - Lateral inhibition matrix
        end
        
      case 'explore'
        
        % Display progress
        fprintf(['Simulating %d trials for trial type %d (of %d) in ', ...
                 'condition %d (of %d) \n'],nSim,iTrType,nTrType,iCnd,nCnd);
        
        % Pre-allocate response and dynamics array
        z = nan(sum(N),nSim,numel(t));
        
        % Getting rid of indexing (and using feval) reduces overhead of
        % parfor loops
        thisSI = diag(SI{iCnd,iTrType});
        thisZC = ZC{iCnd};
        thisT  = t(:)';
        
        % Loop over trials
        parfor iTr = 1:nSim
                                          % OUTPUT                          
          [rt(:,iTr), ...                 % - Response time
           ~, ...                         % - Responses
           z(:,iTr,:)] ...                % - Dynamics
           =  feval ...                   % FUNCTION
           ...                            % INPUT
          (trialSimFun, ...               % - Function handle
           u, ...                         % - Timing diagram of model inputs
           A, ...                         % - Endogenous connectivity matrix
           B, ...                         % - Extrinsic modulation matrix
           C, ...                         % - Exogenous connectivity matrix
           D, ...                         % - Intrinsic modulation matrix
           thisSI, ...                    % - Intrinsic noise matrix
           Z0, ...                        % - Starting point matrix
           thisZC, ...                    % - Threshold matrix
           ZLB, ...                       % - Activation lower bound matrix
           dt, ...                        % - Time step
           tau, ...                       % - Time scale
           thisT, ...                     % - Time points
           terminate, ...                 % - Termination matrix
           blockInput, ...                % - Blocked input matrix
           latInhib);                     % - Lateral inhibition matrix
        end
    end
    
    % 3.4. Classify trials
    % =====================================================================
    
    if iTrType == 1
      
      % 3.4.1. Go correct trial: only one RT, produced by target GO unit
      % -------------------------------------------------------------------
      % Criteria (all should be met):
      % - Target GO unit produced an RT
      % - Target GO unit is the only unit having produced an RT
      iGoCorr = rt(iGOT,:) < Inf & sum(rt < Inf) == 1;
      
      % 3.4.2. Go commission error trial: any RT produced by a non-target GO unit
      % -------------------------------------------------------------------
      % Criteria (all should be met):
      % - At least one non-target GO unit has produced an RT
      iGoComm = any(rt(iGONT,:) < Inf,1);
      
      % 3.4.3. Go omission error trial: no RT
      % -------------------------------------------------------------------
      % Criteria (all should be met):
      % - No unit has produced an RT
      iGoOmit = sum(rt < Inf) == 0;
      
    elseif iTrType > 1
      
      % Stop failure trial
      % -------------------------------------------------------------------
      switch inhibMechType
        case 'race'
          % Criteria
          % - The fastest GO unit has a shorter RT than the STOP unit
          iStopFailure = min(rt(iGO,:),[],1) < rt(iSTOP,:);
          
          % Note: no distinction made between correct and error choice in
          % Go task
          
        otherwise
          % Criteria:
          % - At least one GO unit has produced an RT
          iStopFailure = any(rt(iGO,:) < Inf);
          
          % Note: no distinction made between correct and error choice in
          % Go task
          
          % Note: no distinction made between trials in which the STOP unit
          % did and did not produce an RT (i.e. STOP units cannot terminate
          % the trial under 'blocked input' and 'lateral inhibition'
          % inhibition mechanisms)
          
      end
      
      % Stop success trial
      % -------------------------------------------------------------------
      switch inhibMechType
        case 'race'
          % Criteria (*any* should be met)
          % - STOP unit produces a shorter RT than any other GO units
          % - None of the units produced an RT
          iStopSuccess = rt(iSTOP,:) < min(rt(iGO,:),[],1) | all(rt == Inf);
          
        otherwise
          % Criteria (all should be met):
          % - None of the GO units produced an RT
          iStopSuccess = all(rt(iGO,:) == Inf);
          
%           % Stop succes trial: STOP finishes, *and* none of the GO finishes
%           iStopSuccess = rt(iSTOP,:) < min(rt(iGO,:)) & all(rt == Inf);
          
          % Note: no distinction made between trials in which the STOP unit
          % did and did not produce and RT. We may be more stringent,
          % requiring that STOP finishes, or we could look at how
          % computation of SSRT is influenced by including trials in which
          % STOP did not finish versus when these trials are not included.
          
      end
    end
    
    % 3.5. Log model predictions
    % =====================================================================
    
    % 3.5.1. Trial numbers
    % ---------------------------------------------------------------------
    if iTrType == 1
      nGoCorr(iCnd) = numel(find(iGoCorr));
      nGoComm(iCnd) = numel(find(iGoComm));
      nGoOmit(iCnd) = numel(find(iGoOmit));
    elseif iTrType > 1
      nStopFailure(iCnd,iTrType-1) = numel(find(iStopFailure));
      nStopSuccess(iCnd,iTrType-1) = numel(find(iStopSuccess));
    end
    
    % 3.5.2. Trial probabilities
    % ---------------------------------------------------------------------
    if iTrType == 1
      pGoCorr(iCnd)   = nGoCorr(iCnd)./nSim;
      pGoComm(iCnd)   = nGoComm(iCnd)./nSim;
      pGoOmit(iCnd)   = nGoOmit(iCnd)./nSim;
      
    elseif iTrType > 1
      pStopFailure(iCnd,iTrType-1) = nStopFailure(iCnd,iTrType-1)./nSim;
      pStopSuccess(iCnd,iTrType-1) = nStopSuccess(iCnd,iTrType-1)./nSim;
    end
    
    % 3.5.3. Trial response times
    % ---------------------------------------------------------------------
    if iTrType == 1
      
      % Go correct trials
      if nGoCorr(iCnd) > 0
        rtGoCorr{iCnd}  = sort(rt(iGOT,iGoCorr)) - stimOns{iCnd,iTrType}(iGOT);
      end

      % Go commission error trials
      if nGoComm(iCnd) > 0
        rtGoComm{iCnd}  = sort(min(rt(iGONT,iGoComm),[],1)) - stimOns{iCnd,iTrType}(iGOT);
        % Note: stimOns for GOT and GONT are the same; I use iGOT instead
        % of iGONT because iGOT is always a scalar, iGONT not.
      end
      
    elseif iTrType > 1
      
      % Stop failure trials
      if nStopFailure(iCnd,iTrType-1) > 0
        rtStopFailure{iCnd,iTrType-1} = sort(min(rt(iGO,iStopFailure),[],1)) - stimOns{iCnd,iTrType}(iGOT);
      end
      
      % Stop success trials
      if nStopSuccess(iCnd,iTrType-1) > 0
        rtStopSuccess{iCnd,iTrType-1} = sort(rt(iSTOP,iStopSuccess)) - stimOns{iCnd,iTrType}(iSTOP);
      end
    end
    
    % 3.5.4. Model dynamics
    % ---------------------------------------------------------------------
    
    switch simGoal
      case 'explore'
        if iTrType == 1
          
          % Go correct quantile averaged dynamics
          if nGoCorr(iCnd) >= 1
            
            % Randomly sample one non-target GO unit
            thisIGONT = randsample(iGONT,1);
            
            % Get event times of go-signals and correct responses  
            etGo = repmat(stimOns{iCnd,iTrType}(iGOT),nGoCorr(iCnd),1);
            etResp = rt(iGOT,iGoCorr);
          
            % Get quantile averaged dynamics of GOT aligned on go-signal
            [prd.dyn{iCnd,iTrType}.GoCorr.goStim.GOT.qX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.goStim.GOT.qY, ...
             prd.dyn{iCnd,iTrType}.GoCorr.goStim.GOT.sX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.goStim.GOT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoCorr,iGOT,etGo,CUM_PROB,tWinGo);
            
            
            % Get quantile averaged dynamics of GONT aligned on go-signal
            [prd.dyn{iCnd,iTrType}.GoCorr.goStim.GONT.qX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.goStim.GONT.qY, ...
             prd.dyn{iCnd,iTrType}.GoCorr.goStim.GONT.sX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.goStim.GONT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoCorr,thisIGONT,etGo,CUM_PROB,tWinGo);
            
          
            % Get quantile averaged dynamics of GOT aligned on response
            [prd.dyn{iCnd,iTrType}.GoCorr.resp.GOT.qX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.resp.GOT.qY, ...
             prd.dyn{iCnd,iTrType}.GoCorr.resp.GOT.sX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.resp.GOT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoCorr,iGOT,etResp,CUM_PROB,tWinGo);
            
            % Get quantile averaged dynamics of GONT aligned on response
            [prd.dyn{iCnd,iTrType}.GoCorr.resp.GONT.qX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.resp.GONT.qY, ...
             prd.dyn{iCnd,iTrType}.GoCorr.resp.GONT.sX, ...
             prd.dyn{iCnd,iTrType}.GoCorr.resp.GONT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoCorr,thisIGONT,etResp,CUM_PROB,tWinGo);
          end
          
          if nGoComm(iCnd) >= 1
            
            % Get event times of go-signals and error responses  
            etGo = repmat(stimOns{iCnd,iTrType}(iGOT),nGoComm(iCnd),1);
            [etResp,iGONTE]   = min(rt(:,iGoComm),[],1);
            
            % Get quantile averaged dynamics of GOT aligned on go-signal
            [prd.dyn{iCnd,iTrType}.GoComm.goStim.GOT.qX, ...
             prd.dyn{iCnd,iTrType}.GoComm.goStim.GOT.qY, ...
             prd.dyn{iCnd,iTrType}.GoComm.goStim.GOT.sX, ...
             prd.dyn{iCnd,iTrType}.GoComm.goStim.GOT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoComm,iGOT,etGo,CUM_PROB,tWinGo);
          
            % Get quantile averaged dynamics of GONTE aligned on go-signal
            [prd.dyn{iCnd,iTrType}.GoComm.goStim.GONTE.qX, ...
             prd.dyn{iCnd,iTrType}.GoComm.goStim.GONTE.qY, ...
             prd.dyn{iCnd,iTrType}.GoComm.goStim.GONTE.sX, ...
             prd.dyn{iCnd,iTrType}.GoComm.goStim.GONTE.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoComm,iGONTE,etGo,CUM_PROB,tWinGo);
          
            % Get quantile averaged dynamics of GOT aligned on response
            [prd.dyn{iCnd,iTrType}.GoComm.resp.GOT.qX, ...
             prd.dyn{iCnd,iTrType}.GoComm.resp.GOT.qY, ...
             prd.dyn{iCnd,iTrType}.GoComm.resp.GOT.sX, ...
             prd.dyn{iCnd,iTrType}.GoComm.resp.GOT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoComm,iGOT,etResp,CUM_PROB,tWinResp);
          
            % Get quantile averaged dynamics of GONTE aligned on go-signal
            [prd.dyn{iCnd,iTrType}.GoComm.resp.GONTE.qX, ...
             prd.dyn{iCnd,iTrType}.GoComm.resp.GONTE.qY, ...
             prd.dyn{iCnd,iTrType}.GoComm.resp.GONTE.sX, ...
             prd.dyn{iCnd,iTrType}.GoComm.resp.GONTE.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iGoComm,iGONTE,etResp,CUM_PROB,tWinResp);
          end
          
        elseif iTrType > 1
          
          if nStopFailure(iCnd,iTrType-1) >= 1
            
            % Get event times of go-signals, stop-signals and error responses  
            etGo = repmat(stimOns{iCnd,iTrType}(iGOT),nStopFailure(iCnd,iTrType-1),1);
            etStop = repmat(stimOns{iCnd,iTrType}(iSTOP),nStopFailure(iCnd,iTrType-1),1);
            [etResp,iGORESP]   = min(rt(iGO,iStopFailure),[],1);
            iGORESP = iGO(iGORESP);
            
            % Get quantile averaged dynamics of GORESP aligned on go-signal
            [prd.dyn{iCnd,iTrType}.StopFailure.goStim.GORESP.qX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.goStim.GORESP.qY, ...
             prd.dyn{iCnd,iTrType}.StopFailure.goStim.GORESP.sX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.goStim.GORESP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopFailure,iGORESP,etGo,CUM_PROB,tWinGo);
            
            % Get quantile averaged dynamics of STOP aligned on go-signal
            [prd.dyn{iCnd,iTrType}.StopFailure.goStim.STOP.qX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.goStim.STOP.qY, ...
             prd.dyn{iCnd,iTrType}.StopFailure.goStim.STOP.sX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.goStim.STOP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopFailure,iSTOP,etGo,CUM_PROB,tWinGo);
            
            % Get quantile averaged dynamics of GORESP aligned on stop-signal
            [prd.dyn{iCnd,iTrType}.StopFailure.stopStim.GORESP.qX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.stopStim.GORESP.qY, ...
             prd.dyn{iCnd,iTrType}.StopFailure.stopStim.GORESP.sX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.stopStim.GORESP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopFailure,iGORESP,etStop,CUM_PROB,tWinStop);
            
            % Get quantile averaged dynamics of STOP aligned on stop-signal
            [prd.dyn{iCnd,iTrType}.StopFailure.stopStim.STOP.qX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.stopStim.STOP.qY, ...
             prd.dyn{iCnd,iTrType}.StopFailure.stopStim.STOP.sX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.stopStim.STOP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopFailure,iSTOP,etStop,CUM_PROB,tWinStop);
          
            % Get quantile averaged dynamics of GORESP aligned on response
            [prd.dyn{iCnd,iTrType}.StopFailure.resp.GORESP.qX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.resp.GORESP.qY, ...
             prd.dyn{iCnd,iTrType}.StopFailure.resp.GORESP.sX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.resp.GORESP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopFailure,iGORESP,etResp,CUM_PROB,tWinResp);
            
            % Get quantile averaged dynamics of STOP aligned on response
            [prd.dyn{iCnd,iTrType}.StopFailure.resp.STOP.qX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.resp.STOP.qY, ...
             prd.dyn{iCnd,iTrType}.StopFailure.resp.STOP.sX, ...
             prd.dyn{iCnd,iTrType}.StopFailure.resp.STOP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopFailure,iSTOP,etResp,CUM_PROB,tWinResp);
          
          end
          
          if nStopSuccess(iCnd,iTrType-1) >= 1
            
            % Get event times of go-signals, stop-signals and error responses  
            etGo = repmat(stimOns{iCnd,iTrType}(iGOT),nStopSuccess(iCnd,iTrType-1),1);
            etStop = repmat(stimOns{iCnd,iTrType}(iSTOP),nStopSuccess(iCnd,iTrType-1),1);
            
            % Get quantile averaged dynamics of GORESP aligned on go-signal
            [prd.dyn{iCnd,iTrType}.StopSuccess.goStim.GOT.qX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.goStim.GOT.qY, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.goStim.GOT.sX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.goStim.GOT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopSuccess,iGOT,etGo,CUM_PROB,tWinGo);
            
            % Get quantile averaged dynamics of STOP aligned on go-signal
            [prd.dyn{iCnd,iTrType}.StopSuccess.goStim.STOP.qX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.goStim.STOP.qY, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.goStim.STOP.sX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.goStim.STOP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopSuccess,iSTOP,etGo,CUM_PROB,tWinGo);
            
            % Get quantile averaged dynamics of GORESP aligned on stop-signal
            [prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.GOT.qX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.GOT.qY, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.GOT.sX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.GOT.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopSuccess,iGOT,etStop,CUM_PROB,tWinStop);
            
            % Get quantile averaged dynamics of STOP aligned on stop-signal
            [prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.STOP.qX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.STOP.qY, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.STOP.sX, ...
             prd.dyn{iCnd,iTrType}.StopSuccess.stopStim.STOP.sY] ...
            = sam_get_dynamics('qav-sample100',t,z,iStopSuccess,iSTOP,etStop,CUM_PROB,tWinStop);
          
          end
        end
    end
  end
  
  % 3.5.5. Log inhibition function
  % -----------------------------------------------------------------------
  switch simGoal
    case 'explore'
      switch lower(simScope)
        case 'all'
        inhibFunc{iCnd} = nStopFailure(iCnd,:)./nSim;
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
        prdOptimData.P       = [pGoCorr,pGoComm];
        prdOptimData.rt      = [rtGoCorr,rtGoComm];
      case 'all'
        prdOptimData.P       = [pGoCorr,pGoComm,pStopFailure];
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
    modelMat.accumOns = accumOns;
    modelMat.terminate = terminate;
    modelMat.blockInput = blockInput;
    modelMat.latInhib = latInhib;
        
    % Specify output
    varargout{1} = prd;
    varargout{2} = modelMat;
end