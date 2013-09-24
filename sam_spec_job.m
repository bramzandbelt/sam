% Script specifying job details
%  
% DESCRIPTION 
% This script contains all the details for the job to run
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Mon 09 Sep 2013 13:07:49 CDT by bram 
% $Modified: Sat 21 Sep 2013 12:24:04 CDT by bram

 
% CONTENTS 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. INPUT/OUTPUT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

SAM.io.jobDir                     = '/Users/bramzandbelt/Documents/PROJECTS/SAM/output/test/';
SAM.io.jobName                    = 'test';
SAM.io.outDir                     = '/Users/bramzandbelt/Documents/PROJECTS/SAM/output/test/';


SAM.io.obsFile                    = '/Users/bramzandbelt/Documents/PROJECTS/SAM/output/data_preproc_subj08.mat';

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

SAM.des.choiceMech.type            = 'li';

% #.2. Inhibition mechanism
% ========================================================================= 

% Inhibition mechanism type
% -------------------------------------------------------------------------
% 'race'      - Race
% 'bi'        - Blocked input
% 'li'        - Lateral inhibition

SAM.des.inhibMech.type             = 'li';

% #.3. Accumulation mechanism
% ========================================================================= 

% Lower bound on activation
% -------------------------------------------------------------------------
SAM.des.accumMech.zLB              = 0;

% Time window during which accumulation is 'recorded'
% -------------------------------------------------------------------------
% Time is relative to trial onset
SAM.des.accumMech.timeWindow       = [240 2250];

% Time step
% -------------------------------------------------------------------------
SAM.des.time.dt                    = 1;

% Time constant
% -------------------------------------------------------------------------
SAM.des.time.tau                   = 1;

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
SAM.des.condParam                  = 't0';

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

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY MODEL SIMULATION SETTINGS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% #.#. Goal of simulation
% ========================================================================= 
% Optimization can proceed in two ways:
% 'optimize'   - An optimization algorithm automatically tries to find the
%                 optimal solution to the cost function (specified below).
% 'explore'    - No actual optimization takes place; the model is run and
%                 figures are produced showing observations and model
%                 predictions with current parameters. The parameters can
%                 then be adjusted manually, and the model is run again, in
%                 order to get starting parameters that produce predictions

SAM.sim.goal                          = 'explore';

% #.#. Scope of simulation
% =========================================================================
% This specifies what data will be simulated
% 'go'        - Simulate Go trials only
% 'all'       - Simulate Go and Stop trials

SAM.sim.scope                         = 'all';

% #.#. Number of simulated trials
% =========================================================================
% The same number of trials is used for each trial type

SAM.sim.nSim                          = 10;

% #.#. Random number generator seed
% =========================================================================

SAM.sim.rngID                         = rng('shuffle'); % MATLAB's default


% #.#. Experiment simulation function
% =========================================================================

SAM.sim.exptSimFun                    = @sam_sim_expt;

% #.#. Trial simulation function
% =========================================================================

switch lower([SAM.des.choiceMech.type,'-',SAM.des.inhibMech.type])
  case 'race-race'
    SAM.sim.trialSimFun = @sam_sim_trial_crace_irace_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_crace_irace_nomodbd;
  case 'race-bi'
    SAM.sim.trialSimFun = @sam_sim_trial_crace_ibi_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_crace_ibi_nomodbd;
  case 'race-li'
    SAM.sim.trialSimFun = @sam_sim_trial_crace_ili_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_crace_ili_nomodbd;
  case 'ffi-race'
    SAM.sim.trialSimFun = @sam_sim_trial_cffi_irace_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_cffi_irace_nomodbd;
  case 'ffi-bi'
    SAM.sim.trialSimFun = @sam_sim_trial_cffi_ibi_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_cffi_ibi_nomodbd;
  case 'ffi-li'
    SAM.sim.trialSimFun = @sam_sim_trial_cffi_ili_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_cffi_ili_nomodbd;
  case 'li-race'
    SAM.sim.trialSimFun = @sam_sim_trial_cli_irace_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_cli_irace_nomodbd;
  case 'li-bi'
    SAM.sim.trialSimFun = @sam_sim_trial_cli_ibi_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_cli_ibi_nomodbd;
  case 'li-li'
    SAM.sim.trialSimFun = @sam_sim_trial_cli_ili_nomodbd_mex;
%     SAM.sim.trialSimFun = @sam_sim_trial_cli_ili_nomodbd;
end

% Specify parameter bounds, starting values, and names
% =========================================================================
                                    % OUTPUTS
[LB, ...                            % Lower bounds
 UB, ...                            % Upper bounds 
 X0, ...                            % Starting values
 tg] ...                            % Parameter name
 ...
 = sam_get_bnds(...                 % FUNCTION
 ...                                % INPUTS
 SAM.des.choiceMech.type, ...       % Choice mechanism
 SAM.des.inhibMech.type, ...        % Inhibition mechanism
 SAM.des.condParam, ...             % Parameter varying across conditios
 SAM.sim.scope);  



switch lower(SAM.sim.goal)
  
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY MODEL OPTIMIZATION SETTINGS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
  
  case 'optimize'
    
    % Observations
    % ===================================================================== 
    
    
    % Parameter bounds
    % ===================================================================== 
    
    % Lower bounds
    % ---------------------------------------------------------------------
    SAM.optim.LB                      = LB;
    
    % Upper bounds
    % ---------------------------------------------------------------------
    SAM.optim.UB                      = UB;
    
    % Starting values
    % ---------------------------------------------------------------------
    SAM.optim.X0                      = X0;
    
    % Cost function specifics
    % ===================================================================== 
    
    % Cost function 
    % ---------------------------------------------------------------------
    SAM.optim.costFun                         = @sam_cost_fun;

    % Cost function statistic type
    % ---------------------------------------------------------------------
    SAM.optim.costStat                        = 'chisquare';

    % Cumulative probabilities for which to compute quantiles
    % ---------------------------------------------------------------------
    SAM.optim.cumProb                         = [.1 .3 .5 .7 .9];

    % Minimum bin size (in number of trials per bin)
    SAM.optim.minBinSize                      = 40;
    
    % Optimization solver
    % ===================================================================== 

    % Solver type
    % ---------------------------------------------------------------------
    % de              - differential evolution
    % fminsearchbnd   - constrained simplex
    % ga              - genetic algorithm
    % sa              - simulated annealing

    SAM.optim.solverType              = 'fminsearchbnd';

    % Solver options
    % ---------------------------------------------------------------------
    %
    % Solver            Options structure function    Important fields
    % ------            --------------------------    ---------------------
    % 'de'              ?
    % 'fminsearchbnd'   optimset(@fminsearch)
    % 'ga'              gaoptimset(@ga)
    % 'sa'              saoptimset(@simulannealbnd)
    %

    switch lower(SAM.optim.solverType)
      case 'de'
        error('Don''t know which option structure to use. Implement this.');
      case 'fminsearchbnd'
        SAM.optim.solverOpts            = optimset(@fminsearch);
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

        SAM.optim.solverOpts.MaxFunEvals      = 100;
        SAM.optim.solverOpts.MaxIter          = 100;
        SAM.optim.solverOpts.TolFun           = 1e-4;
        SAM.optim.solverOpts.TolX             = 1e-4;

      case 'ga'

        LB = SAM.optim.solver.LB;
        UB = SAM.optim.solver.UB;

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
    
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. SPECIFY MODEL EXPLORATION SETTINGS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%     
    
  case 'explore'
    
    
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

fName = fullfile(SAM.io.jobDir,[SAM.io.jobName,'.mat']);

save(fName,'SAM');