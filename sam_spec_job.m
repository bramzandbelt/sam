% Script specifying job details
%  
% DESCRIPTION 
% This script contains all the details for the job to run
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Mon 09 Sep 2013 13:07:49 CDT by bram 
% $Modified: Sat 21 Sep 2013 12:24:04 CDT by bram


iStartVal = 1;

 
% CONTENTS 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. INPUT/OUTPUT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Path settings
switch matlabroot
   case '/Applications/MATLAB_R2013a.app' % local
      bzenv('all')
      
      SAM.io.outDir                      = '/Users/bramzandbelt/Documents/PROJECTS/SAM/output/subj08/';
      SAM.io.obsFile                  = '/Users/bramzandbelt/Documents/PROJECTS/SAM/output/subj08/obs.mat';
      
   otherwise   % ACCRE

      addpath('/home/zandbeb/m-files/sam/sam_20131002/');
      addpath(genpath('/home/zandbeb/m-files/general/'));
      
      SAM.io.outDir                      = '/scratch/zandbeb/sam/subj08/';
      SAM.io.obsFile                  = '/scratch/zandbeb/sam/subj08/obs.mat';

end

load(SAM.io.obsFile);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY MODEL DESIGN
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% #.1. Choice mechanism
% ========================================================================= 

% Choice mechanism type
% -------------------------------------------------------------------------
% 'race'      - Race
% 'ffi'       - Feed-forward inhibition
% 'li'        - Lateral inhibition

SAM.des.choiceMech.type            = 'race';

% #.2. Inhibition mechanism
% ========================================================================= 

% Inhibition mechanism type
% -------------------------------------------------------------------------
% 'race'      - Race
% 'bi'        - Blocked input
% 'li'        - Lateral inhibition

SAM.des.inhibMech.type             = 'race';

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

% Parameter that varies across task conditions
% -------------------------------------------------------------------------
SAM.des.condParam                  = 'v';

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

SAM.sim.goal                          = 'optimize';

% #.#. Scope of simulation
% =========================================================================
% This specifies what data will be simulated
% 'go'        - Simulate Go trials only
% 'all'       - Simulate Go and Stop trials

SAM.sim.scope                         = 'go';

% #.#. Number of simulated trials
% =========================================================================
% The same number of trials is used for each trial type

SAM.sim.nSim                          = 2000;

% #.#. Random number generator seed
% =========================================================================

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

    SAM.optim.solverType                      = 'fminsearchcon';
    
    
    
    
    % Specify parameter bounds, starting values, and names
    % =====================================================================
    
    switch lower(SAM.optim.solverType)
      case 'fminsearch'
      case 'fminsearchbnd'
                                            % OUTPUTS
        [LB, ...                            % Lower bounds
         UB, ...                            % Upper bounds 
         ~, ...                             % Starting values
         tg] ...                            % Function accepting X and returning 
         ...
         = sam_get_bnds(...                 % FUNCTION
         ...                                % INPUTS
         SAM);                              % SAM structure
      case 'fminsearchcon'
                                            % OUTPUTS
        [LB, ...                            % Lower bounds
         UB, ...                            % Upper bounds 
         X0, ...                             % Starting values
         tg, ...                            % Parameter name
         linConA, ...                       % Term A in linear inequality A*X <= B
         linConB, ...                       % Term B in linear inequality A*X <= B
         nonLinCon] ...                     % Function accepting X and returning 
         ...                                % nonlinear inequalities and equalities
         ...
         = sam_get_bnds(...                 % FUNCTION
         ...                                % INPUTS
         SAM);                              % SAM structure
      case 'fmincon'
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
         SAM);                              % SAM structure
      case 'ga'
                                            % OUTPUTS
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
         SAM);                              % SAM structure
    end
    
    
    

    % Solver options
    % ---------------------------------------------------------------------
    %
    % Solver            Options structure function    Important fields
    % ------            --------------------------    ---------------------
    % 'de'              ?
    % 'fminsearchcon'   optimset(@fminsearch)
    % 'ga'              gaoptimset(@ga)
    % 'sa'              saoptimset(@simulannealbnd)
    %

    switch lower(SAM.optim.solverType)
      case 'de'
        error('Don''t know which option structure to use. Implement this.');
      case 'fminsearchbnd'
        SAM.optim.solverOpts            = optimset(@fminsearch);
      case 'fminsearchcon'
        SAM.optim.solverOpts            = optimset(@fminsearch);
      case 'fmincon'
        SAM.optim.solverOpts            = optimset(@fmincon);
      case 'ga'
        SAM.optim.solverOpts            = gaoptimset(@ga);
      case 'sa'
        SAM.optim.solverOpts            = saoptimset(@simulannealbnd);
    end

    % General options
    SAM.optim.solverOpts.Display        = 'iter';
    SAM.optim.solverOpts.PlotFcns       = {[]};

    % Solver-specific options
    switch lower(SAM.optim.solverType)
      case 'de'

    %     OPTIONS:
    %  These options may be specified using parameter, value pairs or by
    %  passing a structure. Defaults are shown in parentheses.
    %   popsize        - total number of individuals. (100)
    %   generations    - (10)
    %   strategy       - mutation strategy (see MUTATE for options)
    %   step_weight    - stepsize weight (between 0 and 2) to apply to
    %                    differentials when mutating parameters (0.85)
    %   crossover      - crossover probability constant (between 0 and
    %                    1).  Percentage of random new mutated
    %                    parameters to use in the new population (1)
    %   range_bound    - boolean indicating whether parameters are
    %                    strictly bound by the values in ranges (true)
    %   start_file     - path to a MAT-file containing two variables:
    %                     fitness
    %                     parameters
    %   collect_erfvec - if true, erf values will be saved. (false)


      case 'fminsearchbnd'
        
        SAM.optim.solverOpts.MaxFunEvals      = 150000;
        SAM.optim.solverOpts.MaxIter          = 50;
        SAM.optim.solverOpts.TolFun           = 1e-4;
        SAM.optim.solverOpts.TolX             = 1e-4;
        
      case 'fminsearchcon'

        SAM.optim.solverOpts.MaxFunEvals      = 150000;
        SAM.optim.solverOpts.MaxIter          = 1000;
        SAM.optim.solverOpts.TolFun           = 1e-4;
        SAM.optim.solverOpts.TolX             = 1e-4;
        
      case 'fmincon'
        
        SAM.optim.solverOpts.MaxFunEvals      = 1000;
        SAM.optim.solverOpts.MaxIter          = 50;
        SAM.optim.solverOpts.TolFun           = 1e-4;
        SAM.optim.solverOpts.TolX             = 1e-4;
        SAM.optim.solverOpts.Algorithm        = 'interior-point';
      case 'ga'

        popSize=30;
        nOfColony=1;
        popVec=ones(1,nOfColony)*popSize;

        SAM.optim.solverOpts.PopInitRange     = [LB;UB];
        SAM.optim.solverOpts.PopulationSize   = popVec;
        SAM.optim.solverOpts.EliteCount       = floor(popSize*.2);
        SAM.optim.solverOpts.Generations      = 2;
        SAM.optim.solverOpts.CrossoverFcn     = {@crossoverscattered};
        SAM.optim.solverOpts.MutationFcn      = {@mutationadaptfeasible};
        SAM.optim.solverOpts.SelectionFcn     = {@selectionroulette};
        SAM.optim.solverOpts.Vectorized       = 'off';
        SAM.optim.solverOpts.PlotFcns         = {@gaplotbestf,@gaplotbestindiv};

      case 'sa'

        SAM.optim.solverOpts.PlotFcns         = {@optimplotx, ...
                                                 @optimplotfval, ...
                                                 @optimplotfunccount};
    end
    
    % Read starting values from file
    % ---------------------------------------------------------------------
%     fName = fullfile(SAM.io.outDir,sprintf('x0_%strials_c%s_i%s_p%s.mat', ...
%                                             SAM.sim.scope, ...
%                                             SAM.des.choiceMech.type, ...
%                                             SAM.des.inhibMech.type, ...
%                                             SAM.des.condParam));
%     
%     % Load the file with starting values
%     X0Struct = load(fName,'X0');
% 
%     % Select X0 corresponding to the starting value index
%     SAM.optim.X0                          = X0Struct.X0(iStartVal,:);
    
    
    SAM.optim.X0                         = X0;
    
    
    % Parameter names
    % ---------------------------------------------------------------------
    SAM.optim.XName                       = tg;
    
    % Lower and upper bounds
    % ---------------------------------------------------------------------
    switch lower(SAM.optim.solverType)
      case {'fminsearchbnd','fminsearchcon','fmincon','ga'}
        SAM.optim.LB                      = LB;
        SAM.optim.UB                      = UB;
    end
    
    % Linear and nonlinear (in)equalities
    % ---------------------------------------------------------------------
    switch lower(SAM.optim.solverType)
      case {'fminsearchcon','fmincon','ga'}
        SAM.optim.linConA                 = linConA;
        SAM.optim.linConB                 = linConB;
        SAM.optim.nonLinCon               = nonLinCon;
    end
    
    % Cost function specifics
    % ===================================================================== 
    
    % Cost function 
    % ---------------------------------------------------------------------
    SAM.optim.costFun                         = @sam_cost;

    % Cost function statistic type
    % ---------------------------------------------------------------------
    SAM.optim.costStat                        = 'chisquare';

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
                datestr(now,'yyyy-mm-dd-THHMMSS'), ...
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
    
                                        % OUTPUTS
    [LB, ...                            % Lower bounds
     UB, ...                            % Upper bounds 
     X0, ...                            % Starting values
     tg] ...                            % Function accepting X and returning 
     ...
     = sam_get_bnds(...                 % FUNCTION
     ...                                % INPUTS
     SAM);                              % SAM structure
    
    
    % Starting values
    % ---------------------------------------------------------------------
    SAM.explore.X                                 = X0;
    
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

simGoal         = SAM.sim.goal;
simScope        = SAM.sim.scope;
choiceMechType  = SAM.des.choiceMech.type;
inhibMechType   = SAM.des.inhibMech.type;
condParam       = SAM.des.condParam;

fName = sprintf('job_%s_%strials_c%s_i%s_p%s.mat',simGoal,simScope, ...
                choiceMechType,inhibMechType,condParam);

save(fullfile(SAM.io.outDir,fName),'SAM');