% Script specifying job details
%  
% DESCRIPTION 
% This script contains all the details for the job to run
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Mon 09 Sep 2013 13:07:49 CDT by bram 
% $Modified: Sat 21 Sep 2013 12:24:04 CDT by bram

% Starting parameter index
% -------------------------------------------------------------------------
% There may be a set of starting parameters at which the optimization
% algorithm starts

% CONTENTS 


timeStr = datestr(now,'yyyy-mm-dd-THHMMSS');
tS      = tic;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. SPECIFY THE ENVIRONMENT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% The environment determines the root directory and how model settings are
% specified

switch matlabroot
  case '/Applications/MATLAB_R2013a.app'
    env = 'local';
  otherwise
    env = 'accre';
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. INPUT/OUTPUT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Directories and paths to functions
%
%

% Determine which subject to fit
switch env
  case 'local'
    iSubj = 8;
  case 'accre'
    iSubj = str2double(getenv('subject'));
end

% Path settings
switch env
   case 'local'
      
     % Add directories to search path
      bzenv('all')
      
      % Specify
      rootDir                             = '/Users/bramzandbelt/Dropbox/SAM/data/';
      
  case 'accre'   % ACCRE

      % Add directories to search path
      addpath('/home/zandbeb/sam//');
      addpath(genpath('/home/zandbeb/m-files/general/'));
      
      rootDir                             = '/scratch/zandbeb/sam/';
      
end

% Subject directory and observations file
SAM.io.outDir                       = fullfile(rootDir,sprintf('subj%.2d/',iSubj));
SAM.io.obsFile                      = fullfile(rootDir,sprintf('subj%.2d/obs.mat',iSubj));

load(SAM.io.obsFile);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. SPECIFY MODEL DESIGN
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% #.1. Accumulator classes
% ========================================================================= 

SAM.des.nClass = 2;
SAM.des.classNames = {'GO','STOP'};

% #.1. Choice mechanism
% ========================================================================= 

% Choice mechanism type
% -------------------------------------------------------------------------
% 'race'      - Race
% 'ffi'       - Feed-forward inhibition
% 'li'        - Lateral inhibition

switch env
  case 'local'
    SAM.des.choiceMech.type                 = 'race';
  case 'accre'
    iChoiceMechType = str2double(getenv('choiceMech'));
    switch iChoiceMechType
      case 1
        SAM.des.choiceMech.type             = 'race';
      case 2
        SAM.des.choiceMech.type             = 'ffi';
      case 3
        SAM.des.choiceMech.type             = 'li';
    end
end

% #.2. Inhibition mechanism
% ========================================================================= 

% Inhibition mechanism type
% -------------------------------------------------------------------------
% 'race'      - Race
% 'bi'        - Blocked input
% 'li'        - Lateral inhibition

switch env
  case 'local'
    SAM.des.inhibMech.type                = 'race';
  case 'accre'
    iInhibMechType = str2double(getenv('inhibMech'));
    switch iInhibMechType
      case 1
        SAM.des.inhibMech.type            = 'race';
      case 2
        SAM.des.inhibMech.type            = 'bi';
      case 3
        SAM.des.inhibMech.type            = 'li';
    end
end

% #.3. Accumulation mechanism
% ========================================================================= 

% Lower bound on activation
% -------------------------------------------------------------------------
SAM.des.accumMech.zLB              = 0;

% Time window during which accumulation is 'recorded'
% -------------------------------------------------------------------------
% Time is relative to trial onset
SAM.des.accumMech.timeWindow       = [250 2250];

% Time step
% -------------------------------------------------------------------------
SAM.des.time.dt                    = 5;

% Time constant
% -------------------------------------------------------------------------
SAM.des.time.tau                   = 1;

% Dependency of intrinsic noise on model input
% -------------------------------------------------------------------------
SAM.des.inpDepNoise                = true;

% #.4. Experiment parameters
% ========================================================================= 

% Number of stimuli
% -------------------------------------------------------------------------
SAM.des.expt.nStm                  = [6 1];

% Number of response alternatives
% -------------------------------------------------------------------------
SAM.des.expt.nRsp                  = [6 1];

% Number of task conditions
% -------------------------------------------------------------------------
SAM.des.expt.nCnd                  = 3;

% Number of stop-signal delays
% -------------------------------------------------------------------------
SAM.des.expt.nSsd                  = 5;

% Stimulus onsets
% -------------------------------------------------------------------------
SAM.des.expt.stimOns               = obs.onset;

% Stimulus durations
% -------------------------------------------------------------------------
SAM.des.expt.stimDur               = obs.duration;

% #.5. Model parameters
% ========================================================================= 


% #.5. Model features
% ========================================================================= 

% Number of units
% -------------------------------------------------------------------------
SAM.des.nGO                        = 6;
SAM.des.nSTOP                      = 1;

% Indices of GO inputs, per condition
% -------------------------------------------------------------------------
SAM.des.iGO                        = {3:4,2:5,1:6};

% Indices of target GO inputs, per condition
% -------------------------------------------------------------------------
SAM.des.iGOT                       = {3,3,3};

% Indices of nontarget GO inputs, per condition
% -------------------------------------------------------------------------
SAM.des.iGONT                      = cellfun(@(a,b) setdiff(a,b),SAM.des.iGO,SAM.des.iGOT,'Uni',0);

% Indices of Stop inputs, per condition
% -------------------------------------------------------------------------
SAM.des.iSTOP                      = {7,7,7};

% Duration of STOP process
% -------------------------------------------------------------------------
% 'stop-signal'             - the STOP unit is active for the period that
%                             the stop-signal is presented
% 'trial'                   - the STOP process is active for the entire
%                             duration of the trial

SAM.des.durationSTOP               = 'trial';


% #.#.
% =========================================================================

% Parameter category names
% -------------------------------------------------------------------------
% z0
% zc
% v
% ve
% t0
% se
% si
% k
% w





% Names
SAM.des.XCat.name = {'z0','zc','v','ve','t0','se','si','k','w'};

% Number
SAM.des.XCat.n = numel(SAM.des.XCat.name);

% Indices
SAM.des.XCat.i.iZ0  = 1;  % Starting point
SAM.des.XCat.i.iZc  = 2;  % Response threshold
SAM.des.XCat.i.iV   = 3;  % Driving input to target unit(s)
SAM.des.XCat.i.iVe  = 4;  % Driving input to non-target unit(s)
SAM.des.XCat.i.iT0  = 5;  % Non-decision time
SAM.des.XCat.i.iSe  = 6;  % Extrinsic noise, magnitude
SAM.des.XCat.i.iSi  = 7;  % Intrinsic noise, magnitude
SAM.des.XCat.i.iK   = 8;  % Leakage constant
SAM.des.XCat.i.iW   = 9;  % Lateral connection weights

% Included parameter categories
SAM.des.XCat.included = logical([1 1 1 1 1 0 1 1 1]);

% Class-specific parameter categories
SAM.des.XCat.classSpecific = logical([1 1 1 1 1 0 0 1 1]);

% Value when parameter category is excluded
SAM.des.XCat.valExcluded = [0 Inf 0 0 0 0 0 0 0 0];

% Scaling parameter
SAM.des.XCat.scale.iX   = 7;    % Index of the parameter category
SAM.des.XCat.scale.val  = 1;    % Value of the scaling parameter

% Specify the parameters that potentially could vary across stimuli,
% responses, and conditions (model features)
% -------------------------------------------------------------------------
%
% Does Go RT vary across:
% - primary stimuli?        -> vary GO parameters across stimuli
% - response alternatives?  -> vary GO parameters across responses
% - task conditions?        -> vary GO parameters across conditions
%
% Does SSRT vary across:
% - secondary stimuli?      -> vary STOP parameters across stimuli
% - response alternatives?  -> vary STOP parameters across responses
% - task conditions?        -> vary STOP parameters across conditions

SAM.des.XCat.features = false(3,SAM.des.XCat.n,SAM.des.nClass);

% primary stimuli (e.g. go-left, go-right)
  % None.

% secondary stimuli (e.g. stop, ignore)
  % None.
  
% response Go alternatives (e.g. left hand, right hand)
  % None.
SAM.des.XCat.features(2,SAM.des.XCat.i.iZ0,1)  = 1; % z0
SAM.des.XCat.features(2,SAM.des.XCat.i.iZc,1)  = 1; % zc
  
% response Stop alternatives (this may only be relevant to action-selective
% stopping)
  % None.
  
% Task conditions for GO parameters
SAM.des.XCat.features(3,SAM.des.XCat.i.iZ0,1)  = 1; % z0
SAM.des.XCat.features(3,SAM.des.XCat.i.iZc,1)  = 1; % zc
SAM.des.XCat.features(3,SAM.des.XCat.i.iV,1)   = 1; % v
SAM.des.XCat.features(3,SAM.des.XCat.i.iVe,1)  = 1; % ve
SAM.des.XCat.features(3,SAM.des.XCat.i.iT0,1)  = 1; % t0

% Task conditions for STOP parameters
  % None.


% Compute all possible models and their specifics
models = sam_spec_potential_models(SAM);

% Now, select one model, and get starting parameters, bounds, etc.

model = models(65);


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY MODEL SIMULATION SETTINGS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% #.#. Goal of simulation
% ========================================================================= 
% Optimization can proceed in two ways:
% 'startvals'  - Find good starting values by sampling uniformly 
%                distributed  starting points with bounds, linear, and/or 
%                nonlinear constraints, and then computing the fit between
%                observations and model predictions.
% 'optimize'   - An optimization algorithm automatically tries to find the
%                 optimal solution to the cost function (specified below).
% 'explore'    - No actual optimization takes place; the model is run and
%                 figures are produced showing observations and model
%                 predictions with current parameters. The parameters can
%                 then be adjusted manually, and the model is run again, in
%                 order to get starting parameters that produce predictions

switch env
  case 'local'
    SAM.sim.goal                           = 'explore';
  case 'accre'
    iSimGoal = str2double(getenv('simGoal'));
    switch iSimGoal
      case 1
        SAM.sim.goal                       = 'startvals';
      case 2
        SAM.sim.goal                       = 'optimize';
    end
end

% #.#. Scope of simulation
% =========================================================================
% This specifies what data will be simulated
% 'go'        - Simulate Go trials only
% 'all'       - Simulate Go and Stop trials

switch env
  case 'local'
    SAM.sim.scope                             = 'go';
  case 'accre'
    iSimScope = str2double(getenv('simScope'));
    switch iSimScope
      case 1
        SAM.sim.scope                         = 'go';
      case 2
        SAM.sim.scope                         = 'all';
    end
end

% #.#. Number of simulated trials
% =========================================================================
% The same number of trials is used for each trial type

switch env
  case 'local'
    SAM.sim.nSim                          = 2000;
  case 'accre'
    SAM.sim.nSim                          = str2double(getenv('nSim'));
end


% #.#. Random number generator seed
% =========================================================================

% Reinitialize the random number generator to its startup configuration
rng('default');

% Now, seed the random number generator based on the current time
SAM.sim.rngID                         = rng('shuffle'); % MATLAB's default

% #.#. Moment in the simulation when to seed the random number generator
% =========================================================================
% 'sam_sim_expt'        - The RNG is seeded in sam_sim_expt.m (i.e. every
%                       simulation of an experiment). This will give 
%                       model predictions given identical parameters.
% 'sam_run_job'         - The RNG is seeded in sam_run_job.m (i.e. only 
%                       once). This will usually give different predictions
%                       with identical parameters, because the the 
%                       optimization routine starts from different points
%                       usually.

SAM.sim.rngSeedStage                  = 'sam_sim_expt';

% #.#. Experiment simulation function
% =========================================================================

SAM.sim.exptSimFun                    = @sam_sim_expt;

% #.#. Trial simulation function
% =========================================================================

if SAM.des.inpDepNoise
  switch lower([SAM.des.choiceMech.type,'-',SAM.des.inhibMech.type])
    case 'race-race'
      SAM.sim.trialSimFun = @sam_sim_trial_crace_irace_nomodbd_inpdepnoise_mex;
    case 'race-bi'
      SAM.sim.trialSimFun = @sam_sim_trial_crace_ibi_nomodbd_inpdepnoise_mex;
    case 'race-li'
      SAM.sim.trialSimFun = @sam_sim_trial_crace_ili_nomodbd_inpdepnoise_mex;
    case 'ffi-race'
      SAM.sim.trialSimFun = @sam_sim_trial_cffi_irace_nomodbd_inpdepnoise_mex;
    case 'ffi-bi'
      SAM.sim.trialSimFun = @sam_sim_trial_cffi_ibi_nomodbd_inpdepnoise_mex;
    case 'ffi-li'
      SAM.sim.trialSimFun = @sam_sim_trial_cffi_ili_nomodbd_inpdepnoise_mex;
    case 'li-race'
      SAM.sim.trialSimFun = @sam_sim_trial_cli_irace_nomodbd_inpdepnoise_mex;
    case 'li-bi'
      SAM.sim.trialSimFun = @sam_sim_trial_cli_ibi_nomodbd_inpdepnoise_mex;
    case 'li-li'
      SAM.sim.trialSimFun = @sam_sim_trial_cli_ili_nomodbd_inpdepnoise_mex;
  end
else
  switch lower([SAM.des.choiceMech.type,'-',SAM.des.inhibMech.type])
    case 'race-race'
      SAM.sim.trialSimFun = @sam_sim_trial_crace_irace_nomodbd_mex;
    case 'race-bi'
      SAM.sim.trialSimFun = @sam_sim_trial_crace_ibi_nomodbd_mex;
    case 'race-li'
      SAM.sim.trialSimFun = @sam_sim_trial_crace_ili_nomodbd_mex;
    case 'ffi-race'
      SAM.sim.trialSimFun = @sam_sim_trial_cffi_irace_nomodbd_mex;
    case 'ffi-bi'
      SAM.sim.trialSimFun = @sam_sim_trial_cffi_ibi_nomodbd_mex;
    case 'ffi-li'
      SAM.sim.trialSimFun = @sam_sim_trial_cffi_ili_nomodbd_mex;
    case 'li-race'
      SAM.sim.trialSimFun = @sam_sim_trial_cli_irace_nomodbd_mex;
    case 'li-bi'
      SAM.sim.trialSimFun = @sam_sim_trial_cli_ibi_nomodbd_mex;
    case 'li-li'
      SAM.sim.trialSimFun = @sam_sim_trial_cli_ili_nomodbd_mex;
  end
end

% Starting value index
% -------------------------------------------------------------------------
% There may be a set of starting values from which optimization begins

switch lower(env)
  case 'local'
    iStartVal = 1;
  case 'accre'
    iStartVal = str2double(getenv('iStartVal'));
end

switch lower(SAM.sim.goal)
  
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY STARTING POINT EXPLORATION SETTINGS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%         
    
  case 'startvals'
    
    % Number of starting points
    SAM.startvals.nX0     = 100;

    % Specify parameter bounds, starting values, and names
    % =====================================================================
    [LB, ...                            % Lower bounds
     UB, ...                            % Upper bounds 
     ~, ...                             % Starting values
     tg, ...                            % Parameter name
     linConA, ...                       % Term A in linear inequality A*X <= B
     linConB, ...                       % Term B in linear inequality A*X <= B
     nonLinCon] ...                     % Function accepting X and returning 
     ...                                % nonlinear inequalities and equalities
     ...
     = sam_get_bnds(...                 % FUNCTION
     ...                                % INPUTS
     SAM);  

    % Lower bounds
    SAM.startvals.LB          = LB;
    
    % Upper bounds
    SAM.startvals.UB          = UB;
    
    % Linear constraints
    SAM.startvals.linConA     = linConA;
    SAM.startvals.linConB     = linConB;

    % Nonlinear constraints
    SAM.startvals.nonLinCon   = nonLinCon;
    
    
    % Cost function specifics
    % ===================================================================== 
    
    % Cost function 
    % ---------------------------------------------------------------------
    SAM.startvals.costFun                         = @sam_cost;

    % Cost function statistic type
    % ---------------------------------------------------------------------
    SAM.startvals.costStat                        = 'chisquare';

    % Cumulative probabilities for which to compute quantiles
    % ---------------------------------------------------------------------
    SAM.startvals.cumProb                         = [.1 .3 .5 .7 .9];

    % Minimum bin size (in number of trials per bin)
    SAM.startvals.minBinSize                      = 40;
    
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY MODEL OPTIMIZATION SETTINGS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  



  case 'optimize'
    
    % Optimization solver
    % ===================================================================== 

    % Solver type
    % ---------------------------------------------------------------------
    % de              - differential evolution
    % fminsearchbnd   - bounded simplex
    % fminsearchcon   - constrained simplex
    % fmincon         - find constrained minimum with 'interior-point'
    %                   algorithm
    % ga              - genetic algorithm
    % sa              - simulated annealing

    SAM.optim.solverType  = 'fminsearchcon';
    SAM.optim.solverOpts  = sam_get_solver_opts('fminsearchcon');
    
    % Initial parameters
    % ===================================================================== 
    X0                    = sam_get_x0(SAM);
    SAM.optim.X0          = X0;
    
    % Alternatively, a row vector of parameters can be specified. The
    % number should correspond to the sum of the vector in model.XSpec.n,
    % e.g.:
    % SAM.optim.X0 = [0 0 100 100 ... -realmin];
    
    % Parameter constraints
    % ===================================================================== 
    
    % Hard lower and upper bounds
    SAM.des.XCat.hardLB   = [zLB 0   0   0   0   0   0   -Inf     -Inf];
    SAM.des.XCat.hardUB   = [Inf Inf Inf Inf Inf Inf Inf -realmin -realmin];

    % Bound distance from initial paremeter value for each parameter
    % category. This can be additive and/or multiplicative.
    SAM.des.XCat.additive       = [0   0   0   0   0   0   0   0.5 1];
    SAM.des.XCat.multiplicative = [0.5 0.5 0.5 0.5 0.5 0.5 0.5 0   0];
        
    constraint            = sam_get_constraint(SAM);
    SAM.optim.constraint  = constraint;
        
    % Cost function specifics
    % ===================================================================== 
    
    % Cost function 
    % ---------------------------------------------------------------------
    SAM.optim.cost.fun                         = @sam_cost;

    % Cost function statistic type
    % ---------------------------------------------------------------------
    SAM.optim.cost.stat                        = 'chisquare';

    % Cumulative probabilities for which to compute quantiles
    % ---------------------------------------------------------------------
    SAM.optim.cumProb                         = [.1 .3 .5 .7 .9];

    % Minimum bin size (in number of trials per bin)
    SAM.optim.minBinSize                      = 40;
        
    % Logging optimization
    % ===================================================================== 
    
    % File name of observations file
    [~,fName,fExt] = fileparts(SAM.io.obsFile);
    
    % General file name string for iteration and final log file
    fNameStr = [fName,'_', ...
                'c',SAM.des.choiceMech.type,'_', ...
                'i',SAM.des.inhibMech.type,'_', ...
                SAM.des.condParam,'_', ...
                SAM.sim.scope,'Trials_', ...
                'iX',sprintf('%.3d',iStartVal),'_' ...
                timeStr, ...
                '.mat'];
    
    % Iteration log file
    % ---------------------------------------------------------------------
    SAM.optim.iterLogFile = fullfile(SAM.io.outDir,['iterLog_',fNameStr]);
    
    % Iteration log frequency
    % ---------------------------------------------------------------------
    % Set to inf if iterations should not be logged
    SAM.optim.iterLogFreq = 50; % Iterations
    
    % Final log file
    % ---------------------------------------------------------------------
    SAM.optim.finalLogFile = fullfile(SAM.io.outDir,['finalLog_',fNameStr]);
   
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY MODEL EXPLORATION SETTINGS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
    
  case 'explore'
        
    % Starting values
    % ---------------------------------------------------------------------
    
    outDir = SAM.io.outDir;
    choiceMechType = SAM.des.choiceMech.type;
    inhibMechType = SAM.des.inhibMech.type;
    condParam = SAM.des.condParam;
    simScope = SAM.sim.scope;
    
    % Specify file with starting values
    X0fName = sprintf('x0_%strials_c%s_i%s_p%s.mat',simScope, ...
                choiceMechType,inhibMechType,condParam);
    X0Path = fullfile(outDir,X0fName);

    % Load the file with starting values
    X0Struct = load(X0Path);
    
    % Set the starting values and parameter names
    SAM.explore.X                          = X0Struct.X0(iStartVal,:);
    SAM.explore.XName                      = X0Struct.tg;
    
    % #.#. Time windows for event alignments
    % =====================================================================
    
    % Alignment on go-signal
    SAM.explore.tWinGo                            = [-250 2250];
    
    % Alignment on stop-signal
    SAM.explore.tWinStop                          = [-250 2250];  
    
    % Alignment on response
    SAM.explore.tWinResp                          = [-500 0];
    
    % #.#. Whether or not to plot RT distributions
    % =====================================================================
    SAM.explore.doPlot                            = false;
     
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SAVE JOB
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch env
  case 'local' % Run job, do not save it
  case 'accre' % Save and run job
    simGoal         = SAM.sim.goal;
    simScope        = SAM.sim.scope;
    choiceMechType  = SAM.des.choiceMech.type;
    inhibMechType   = SAM.des.inhibMech.type;
    condParam       = SAM.des.condParam;

    fName = sprintf('job_%s_%strials_c%s_i%s_p%s_iX%s_%s.mat',simGoal,simScope, ...
                    choiceMechType,inhibMechType,condParam,sprintf('%.3d',iStartVal),timeStr);

    save(fullfile(SAM.io.outDir,fName),'SAM');
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. RUN JOB
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch lower(SAM.sim.goal)
  case 'startvals'
    sam_run_job(SAM);
  case 'optimize'
    [X,fVal,exitFlag,solverOutput,history] = sam_run_job(SAM);
    tElapse = toc(tS);
    assignin('base','X',X);
    assignin('base','fVal',fVal);
    assignin('base','exitFlag',exitFlag);
    assignin('base','solverOutput',solverOutput);
    assignin('base','history',history);
    assignin('base','tElapse',tElapse);
  case 'explore'
    [prd,modelMat] = sam_run_job(SAM);
    tElapse = toc(tS);
    assignin('base','prd',prd);
    assignin('base','modelMat',modelMat);
    assignin('base','tElapse',tElapse);
end
  