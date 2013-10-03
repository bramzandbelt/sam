function [LB,UB,X0,tg,linconA,linconB,nonlincon] = sam_get_bnds(varargin)
% Returns parameter bounds, starting values, and names for given model
%  
% DESCRIPTION 
% Returns parameter lower and upper bounds, starting values, and names, 
% based on the specified choice mechanism, inhibition mechanism, condition 
% parameter, and scope of simulation.
% 
%  
% SYNTAX 
% SAM_GET_BNDS; 
% choiceMechType  - choice mechanism (char array)
%                   * 'race', race
%                   * 'ffi', feed-forward inhibition
%                   * 'li', lateral inhibition
% inhibMechType   - inhibition mechanism (char array)
%                   * 'race', race
%                   * 'bi', blocked-input
%                   * 'li', lateral inhibition
% condParam       - condition parameter (char array)
%                   * 't0', non-decision time
%                   * 'v', accumulation rate of target
%                   * 'zc', threshold
% simGoal         - goal of the simulation (char array)
%                   * 'optimize'
%                   * 'explore'
% simScope        - scope of simulation (char array)
%                   * 'go', only go trials
%                   * 'all', go and stopp trials
% solverType      - type of optimization solver (this will cause changes in
%                   whether nonlincon contains only c or also ceq)
% 
%
% LB              - lower bounds of parameters
% UB              - upper bounds of parameters
% X0              - starting values of parameters
% tg              - parameter names
% linconA         - term A in the linear inequality A*X <= B
% linconB         - term B in the linear inequality A*X <= B
% nonlincon       - function accepting X and returning the nonlinear
%                   inequalities and equalities
%
% EXAMPLE
% [LB,UB,X0,tg,linconA,linconB,nonlincon] = sam_get_bnds('race','race','t0','optimize','all');
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Thu 19 Sep 2013 09:48:27 CDT by bram 
% $Modified: Sat 21 Sep 2013 12:03:08 CDT by bram

% CONTENTS 
% 1.SET LB, UB, X0 VALUES
%   1.1.Starting value (z0)
%       1.1.1.GO units
%       1.1.2.STOP unit
%   1.2.Threshold (zc)
%       1.2.1.GO units
%       1.2.2.STOP unit
%   1.3.Accumulation rate correct (vCor)
%       1.3.1.GO units
%       1.3.2.STOP unit
%   1.4.Accumulation rate incorrect (vIncor)
%   1.5.Non-decision time (t0)
%       1.5.1.GO units
%       1.5.2.STOP unit
%   1.6.Extrinsic noise (se)
%   1.7.Intrinsic noise (si)
%   1.8.Leakage constant (k)
%       1.8.1.GO units
%       1.8.2.STOP unit
%   1.9.Lateral inhibition weight (w)
%       1.9.1.GO units
%       1.9.2.STOP unit
% 2. GENERATE LB, UB, AND X0 VECTORS


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Process inputs
% ========================================================================= 

if nargin == 1  % Input is SAM
  
  SAM = varargin{1};
  
  % Choice mechanism
  % -------------------------------------------------------------------------
  choiceMechType      = SAM.des.choiceMech.type;

  % Inhibition mechanism
  % -------------------------------------------------------------------------
  inhibMechType       = SAM.des.inhibMech.type;

  % Parameter that varies across task conditions
  % -------------------------------------------------------------------------
  condParam           = SAM.des.condParam;

  % Goal of the simulation
  % -------------------------------------------------------------------------
  simGoal             = SAM.sim.goal;

  % Scope of the simulation
  % -------------------------------------------------------------------------
  simScope            = SAM.sim.scope;
  
  
  switch lower(simGoal)
    case 'optimize'
      % Type of optimization solver
      % -------------------------------------------------------------------
      solverType          = SAM.optim.solverType;
  end
  

elseif nargin > 1 % Input is something like ('race,'race','t0','optimize','all')
  
  choiceMechType      = varargin{1};
  inhibMechType       = varargin{2};
  condParam           = varargin{3};
  simGoal             = varargin{4};
  simScope            = varargin{5};
  
  switch lower(simGoal)
    case 'optimize'
      solverType = varargin{6};
  end
end

% 1.2. Specify static variables
  % ========================================================================= 

  % How far the lower and upper bounds are set from the best-fitting
  % parameter (fraction between 0 and 1)

  boundDist           = 0.5;

% 1.3. Specify dynamic variables
% ========================================================================= 

% load(SAM.io.obsFile);
%     
% % All observed RTs
% obsRt = cell2mat([obs.rtGoCorr(:);obs.rtGoComm(:);obs.rtStopFailure(:)]);
% 
% switch lower(simGoal)
%   case 'optimize'
%     
%     solverType = SAM.optim.solverType;
%     
%   case 'startvals'
%     
%     solverType = 'fmincon'; % This is just to get the linear and nonlinear constraints
%     
% end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. SET LB, UB, X0 VALUES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Starting value (z0)
% ========================================================================= 

% 1.1.1. GO units
% -------------------------------------------------------------------------
% z0GLB     = 0;
% z0GUB     = 200;
% z0GX0     = 7.44e-5;
z0GX0     = 7.44e-5;
z0Gtg     = 'z0G';
z0GLB     = (1-boundDist)*z0GX0;
z0GUB     = (1+boundDist)*z0GX0;
             
% 1.1.2. STOP unit
% -------------------------------------------------------------------------
z0SX0     = 2.26e-10;
z0Stg     = 'z0S';
z0SLB     = (1-boundDist)*z0SX0;
z0SUB     = (1+boundDist)*z0SX0;

% 1.2. Threshold (zc)
% ========================================================================= 

% 1.2.1. GO units
% -------------------------------------------------------------------------

switch lower(condParam)
  case 'zc'
    zcGX0_c1  = 38.49;
    zcGX0_c2  = 55.95;
    zcGX0_c3  = 70.08;
    zcGtg_c1   = 'zcG_c1';
    zcGtg_c2   = 'zcG_c2';
    zcGtg_c3   = 'zcG_c3';
    zcGLB     = (1-boundDist)*min([zcGX0_c1,zcGX0_c2,zcGX0_c3]);
    zcGUB     = (1+boundDist)*max([zcGX0_c1,zcGX0_c2,zcGX0_c3]);
  otherwise
    zcGX0     = 69.83;
    zcGtg     = 'zcG';
    zcGLB     = (1-boundDist)*zcGX0;
    zcGUB     = (1+boundDist)*zcGX0;
end

% 1.2.2. STOP unit
% -------------------------------------------------------------------------
zcSX0     = 9.67;
zcStg     = 'zcS';
zcSLB     = (1-boundDist)*zcSX0;
zcSUB     = (1+boundDist)*zcSX0;


% 1.3. Accumulation rate correct (vCor)
% ========================================================================= 
                 
% 1.3.1. GO units
% -------------------------------------------------------------------------

switch lower(condParam)
  case 'v'
    vCGX0_c1  = 0.2044;
    vCGX0_c2  = 0.1325;
    vCGX0_c3  = 0.1013;
    vCGtg_c1  = 'vCG_c1';
    vCGtg_c2  = 'vCG_c2';
    vCGtg_c3  = 'vCG_c3';
    vCGLB     = (1-boundDist)*min([vCGX0_c1,vCGX0_c2,vCGX0_c3]);
    vCGUB     = (1+boundDist)*max([vCGX0_c1,vCGX0_c2,vCGX0_c3]);
  otherwise
    vCGX0     = 0.1188;
    vCGtg     = 'vCG';
    vCGLB     = (1-boundDist)*vCGX0;
    vCGUB     = (1+boundDist)*vCGX0;
end

% 1.3.2. STOP unit
% -------------------------------------------------------------------------
vCSX0     = 0.761;
vCStg     = 'vCS';
vCSLB     = (1-boundDist)*vCSX0;
vCSUB     = (1+boundDist)*vCSX0;


% 1.4. Accumulation rate incorrect (vIncor)
% ========================================================================= 
     
% 1.4.1.  units
% -------------------------------------------------------------------------
switch lower(condParam)
  case 'v'
    vIGX0_c1  = 0.0584;
    vIGX0_c2  = 0.0144;
    vIGX0_c3  = 5.55e-19;
    vIGtg_c1  = 'vIG_c1';
    vIGtg_c2  = 'vIG_c2';
    vIGtg_c3  = 'vIG_c3';
    vIGLB     = (1-boundDist)*min([vIGX0_c1,vIGX0_c2,vIGX0_c3]);
    vIGUB     = (1+boundDist)*max([vIGX0_c1,vIGX0_c2,vIGX0_c3]);
  otherwise
    vIGX0     = 8.75e-13;
    vIGtg     = 'vIG';
    vIGLB     = (1-boundDist)*vIGX0;
    vIGUB     = (1+boundDist)*vIGX0;
end

% 1.5. Non-decision time (t0)
% ========================================================================= 

% 1.5.1. GO units
% -------------------------------------------------------------------------
switch lower(condParam)
  case 't0'
    t0GX0_c1  = 77;
    t0GX0_c2  = 117;
    t0GX0_c3  = 157;
    t0Gtg_c1  = 't0G_c1';
    t0Gtg_c2  = 't0G_c2';
    t0Gtg_c3  = 't0G_c3';
    t0GLB     = (1-boundDist)*min([t0GX0_c1,t0GX0_c2,t0GX0_c3]);
    t0GUB     = (1+boundDist)*max([t0GX0_c1,t0GX0_c2,t0GX0_c3]);
  otherwise
    t0GX0     = 117;
    t0Gtg     = 't0G';
    t0GLB     = (1-boundDist)*t0GX0;
    t0GUB     = (1+boundDist)*t0GX0;
end

% 1.5.2. STOP unit
% -------------------------------------------------------------------------
t0SX0     = 240;
t0Stg     = 't0S';
t0SLB     = (1-boundDist)*t0SX0;
t0SUB     = (1+boundDist)*t0SX0;


% 1.6. Extrinsic noise (se)
% ========================================================================= 
seX0      = 0;
setg      = 'se';
seLB      = 0;
seUB      = 0;


% 1.7. Intrinsic noise (si)
% ========================================================================= 
siX0      = 1;
sitg      = 'si';
siLB      = 1;
siUB      = 1;


% 1.8. Leakage constant (k)
% ========================================================================= 

% 1.8.1. GO units
% -------------------------------------------------------------------------
kGX0      = -realmin;
kGtg      = 'kG';
kGLB      = -realmin;
kGUB      = -realmin;     % Note: this should not be 0 to satisfy non-linear constraints

% 1.8.2. STOP unit
% -------------------------------------------------------------------------
kSX0      = -realmin;
kStg      = 'kS';
kSLB      = -realmin;
kSUB      = -realmin;     % Note: this should not be 0 to satisfy non-linear constraints

% 1.9. Lateral inhibition weight (w)
% ========================================================================= 

% 1.9.1. GO units
% -------------------------------------------------------------------------
wGX0      = -0.01;
wGtg      = 'wG';
wGLB      = -0.2;
wGUB      = 0;

% 1.9.2. STOP unit
% -------------------------------------------------------------------------
wSX0      = -0.2;
wStg      = 'wS';
wSLB      = -1;
wSUB      = 0;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. GENERATE LB, UB, AND X0 VECTORS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch lower(condParam)
  case 't0'
    switch lower(simScope)
      case 'go'
        switch lower(choiceMechType)
          case 'li'
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % L-R-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            % L-B-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            % L-L-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            
            X0 = [z0GX0,zcGX0,vCGX0,vIGX0,t0GX0_c1,t0GX0_c2,t0GX0_c3,seX0,siX0,kGX0,wGX0];
            tg = {z0Gtg,zcGtg,vCGtg,vIGtg,t0Gtg_c1,t0Gtg_c2,t0Gtg_c3,setg,sitg,kGtg,wGtg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}
                
                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,zcGLB,vCGLB,vIGLB,t0GLB,t0GLB,t0GLB,seLB,siLB,kGLB,wGLB];
                UB = [z0GUB,zcGUB,vCGUB,vIGUB,t0GUB,t0GUB,t0GUB,seUB,siUB,kGUB,wGUB];
                
                % Linear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case {'fminsearchcon','fmincon','ga'}
                    linconA = [1 -1 0 0 0 0 0 0 0 0 0]; % z0G - zcG <= 0
                    linconB = 0;
                end
                
                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) x(2) - x(3)./-x(10); % zcG - vCG./-kG <= 0
                    
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c = @(x) x(2) - x(3) ./ -x(10);       % zcG - vCG./-kG <= 0
                    ceq = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
            
          case {'race','ffi'}
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % R-R-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % R-B-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % R-L-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-R-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-B-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-L-T0-G    | 1 | 0 | 1 | 0 | 1 | 0 | 1 | 3 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            
            X0 = [z0GX0,zcGX0,vCGX0,vIGX0,t0GX0_c1,t0GX0_c2,t0GX0_c3,seX0,siX0,kGX0];
            tg = {z0Gtg,zcGtg,vCGtg,vIGtg,t0Gtg_c1,t0Gtg_c2,t0Gtg_c3,setg,sitg,kGtg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}
                
                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,zcGLB,vCGLB,vIGLB,t0GLB,t0GLB,t0GLB,seLB,siLB,kGLB];
                UB = [z0GUB,zcGUB,vCGUB,vIGUB,t0GUB,t0GUB,t0GUB,seUB,siUB,kGUB];
                
                % Linear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case {'fminsearchcon','fmincon','ga'}
                    linconA = [1 -1 0 0 0 0 0 0 0 0]; % z0G - zcG <= 0
                    linconB = 0;
                end
                
                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) x(2) - x(3)./-x(10); % zcG - vCG./-kG <= 0
                    
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c = @(x) x(2) - x(3)./-x(10);         % zcG - vCG./-kG <= 0
                    ceq = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
        end        
      case 'all'
        switch lower(choiceMechType)
          case 'li'
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % L-R-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            % L-B-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            % L-L-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            
            X0 = [z0GX0,z0SX0,zcGX0,zcSX0,vCGX0,vCSX0,vIGX0,t0GX0_c1,t0GX0_c2,t0GX0_c3,t0SX0,seX0,siX0,kGX0,kSX0,wGX0,wSX0];
            tg = {z0Gtg,z0Stg,zcGtg,zcStg,vCGtg,vCStg,vIGtg,t0Gtg_c1,t0Gtg_c2,t0Gtg_c3,t0Stg,setg,sitg,kGtg,kStg,wGtg,wStg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}
                
                % Bounds
                % ---------------------------------------------------------
                
                LB = [z0GLB,z0SLB,zcGLB,zcSLB,vCGLB,vCSLB,vIGLB,t0GLB,t0GLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB,wGLB,wSLB];
                UB = [z0GUB,z0SUB,zcGUB,zcSUB,vCGUB,vCSUB,vIGUB,t0GUB,t0GUB,t0GUB,t0SUB,seUB,siUB,kGUB,kSUB,wGUB,wSUB];
                
                % Linear constraints
                % ---------------------------------------------------------
                
                linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG <= 0
                           0 1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                linconB = [0; ...
                           0];
                
                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) [x(3) - x(5)./-x(14); ...  % zcG - vCG./-kG <= 0
                                      x(4) - x(6)./-x(15)];     % zcS - vCS./-kS <= 0
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c(1)      = @(x) [x(3) - x(5)./-x(14); ...  % zcG - vCG./-kG <= 0
                                      x(4) - x(6)./-x(15)];     % zcS - vCS./-kS <= 0
                    ceq       = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
          case {'race','ffi'}
            switch lower(inhibMechType)
              case 'li'
                % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
                % R-L-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
                % F-L-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
                
                X0 = [z0GX0,z0SX0,zcGX0,zcSX0,vCGX0,vCSX0,vIGX0,t0GX0_c1,t0GX0_c2,t0GX0_c3,t0SX0,seX0,siX0,kGX0,kSX0,wGX0,wSX0];
                tg = {z0Gtg,z0Stg,zcGtg,zcStg,vCGtg,vCStg,vIGtg,t0Gtg_c1,t0Gtg_c2,t0Gtg_c3,t0Stg,setg,sitg,kGtg,kStg,wGtg,wStg};
                
                switch lower(simGoal)
                  case {'optimize','startvals'}

                    % Bounds
                    % -----------------------------------------------------
                    LB = [z0GLB,z0SLB,zcGLB,zcSLB,vCGLB,vCSLB,vIGLB,t0GLB,t0GLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB,wGLB,wSLB];
                    UB = [z0GUB,z0SUB,zcGUB,zcSUB,vCGUB,vCSUB,vIGUB,t0GUB,t0GUB,t0GUB,t0SUB,seUB,siUB,kGUB,kSUB,wGUB,wSUB];

                    % Linear constraints
                    % -----------------------------------------------------
                    linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG <= 0
                               0 1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                    linconB = [0, ...
                               0];

                    % Nonlinear constraints
                    % -----------------------------------------------------
                    switch lower(solverType)
                      case 'fminsearchcon'
                        % Inequality constraints
                        nonlincon = @(x) [x(3) - x(5)./-x(14); ...  % zcG - vCG./-kG <= 0
                                          x(4) - x(6)./-x(15)];     % zcS - vCS./-kS <= 0
                      case {'fmincon','ga'}
                        % Inequality and equality constraints
                        c(1)      = @(x) [x(3) - x(5)./-x(14); ...  % zcG - vCG./-kG <= 0
                                          x(4) - x(6)./-x(15)];     % zcS - vCS./-kS <= 0
                        ceq       = @(x) [];

                        nonlincon = @(x) deal(c(x),ceq(x));
                    end
                end                
              case {'race','bi'}
                % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
                % R-R-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % R-B-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % F-R-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % F-B-T0-A    | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                
                X0 = [z0GX0,z0SX0,zcGX0,zcSX0,vCGX0,vCSX0,vIGX0,t0GX0_c1,t0GX0_c2,t0GX0_c3,t0SX0,seX0,siX0,kGX0,kSX0];
                tg = {z0Gtg,z0Stg,zcGtg,zcStg,vCGtg,vCStg,vIGtg,t0Gtg_c1,t0Gtg_c2,t0Gtg_c3,t0Stg,setg,sitg,kGtg,kStg};
                
                switch lower(simGoal)
                  case {'optimize','startvals'}

                    % Bounds
                    % -----------------------------------------------------
                    LB = [z0GLB,z0SLB,zcGLB,zcSLB,vCGLB,vCSLB,vIGLB,t0GLB,t0GLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB];
                    UB = [z0GUB,z0SUB,zcGUB,zcSUB,vCGUB,vCSUB,vIGUB,t0GUB,t0GUB,t0GUB,t0SUB,seUB,siUB,kGUB,kSUB];

                    % Linear constraints
                    % -----------------------------------------------------
                    linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG <= 0
                               0 1 0 -1 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                    linconB = [0; ...
                               0];

                    % Nonlinear constraints
                    % -----------------------------------------------------
                    switch lower(solverType)
                      case 'fminsearchcon'
                        % Inequality constraints
                        nonlincon = @(x) [x(3) - x(5)./-x(14); ...  % zcG - vCG./-kG <= 0
                                          x(4) - x(6)./-x(15)];     % zcS - vCS./-kS <= 0
                      case {'fmincon','ga'}
                        % Inequality and equality constraints
                        c(1)      = @(x) [x(3) - x(5)./-x(14); ...  % zcG - vCG./-kG <= 0
                                          x(4) - x(6)./-x(15)];     % zcS - vCS./-kS <= 0
                        ceq       = @(x) [];

                        nonlincon = @(x) deal(c(x),ceq(x));
                    end
                end
            end
        end 
    end
  case 'v'
    switch lower(simScope)
      case 'go'
        switch lower(choiceMechType)
          case 'li'
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % L-R-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            % L-B-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            % L-L-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            
            X0 = [z0GX0,zcGX0,vCGX0_c1,vCGX0_c2,vCGX0_c3,vIGX0_c1,vIGX0_c2,vIGX0_c3,t0GX0,seX0,siX0,kGX0,wGX0];
            tg = {z0Gtg,zcGtg,vCGtg_c1,vCGtg_c2,vCGtg_c3,vIGtg_c1,vIGtg_c2,vIGtg_c3,t0Gtg,setg,sitg,kGtg,wGtg};
            
            
            switch lower(simGoal)
              case {'optimize','startvals'}

                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,zcGLB,vCGLB,vCGLB,vCGLB,vIGLB,vIGLB,vIGLB,t0GLB,seLB,siLB,kGLB,wGLB];
                UB = [z0GUB,zcGUB,vCGUB,vCGUB,vCGUB,vIGUB,vIGUB,vIGUB,t0GUB,seUB,siUB,kGUB,wGUB];
                
                % Linear constraints
                % ---------------------------------------------------------
                linconA = [1 -1 0 0 0 0 0 0 0 0 0 0 0]; % z0G - zcG <= 0
                linconB = 0;

                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) [x(2) - x(3)./-x(12); ...  % zcG - vCG_c1./-kG <= 0
                                      x(2) - x(4)./-x(12); ...  % zcG - vCG_c2./-kG <= 0
                                      x(2) - x(5)./-x(12)]; ... % zcG - vCG_c3./-kG <= 0
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c         = @(x) [x(2) - x(3)./-x(12); ...  % zcG - vCG_c1./-kG <= 0
                                      x(2) - x(4)./-x(12); ...  % zcG - vCG_c2./-kG <= 0
                                      x(2) - x(5)./-x(12)]; ... % zcG - vCG_c3./-kG <= 0

                    ceq       = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
          case {'race','ffi'}
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % R-R-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % R-B-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % R-L-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-R-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-B-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-L-V-G     | 1 | 0 | 1 | 0 | 3 | 0 | 3 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            
            X0 = [z0GX0,zcGX0,vCGX0_c1,vCGX0_c2,vCGX0_c3,vIGX0_c1,vIGX0_c2,vIGX0_c3,t0GX0,seX0,siX0,kGX0];
            tg = {z0Gtg,zcGtg,vCGtg_c1,vCGtg_c2,vCGtg_c3,vIGtg_c1,vIGtg_c2,vIGtg_c3,t0Gtg,setg,sitg,kGtg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}

                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,zcGLB,vCGLB,vCGLB,vCGLB,vIGLB,vIGLB,vIGLB,t0GLB,seLB,siLB,kGLB];
                UB = [z0GUB,zcGUB,vCGUB,vCGUB,vCGUB,vIGUB,vIGUB,vIGUB,t0GUB,seUB,siUB,kGUB];

                % Linear constraints
                % ---------------------------------------------------------
                linconA = [1 -1 0 0 0 0 0 0 0 0 0 0]; % z0G - zcG <= 0
                linconB = 0;

                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) [x(2) - x(3)./-x(12); ...  % zcG - vCG_c1./-kG <= 0
                                      x(2) - x(4)./-x(12); ...  % zcG - vCG_c2./-kG <= 0
                                      x(2) - x(5)./-x(12)]; ... % zcG - vCG_c3./-kG <= 0
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c         = @(x) [x(2) - x(3)./-x(12); ...  % zcG - vCG_c1./-kG <= 0
                                      x(2) - x(4)./-x(12); ...  % zcG - vCG_c2./-kG <= 0
                                      x(2) - x(5)./-x(12)]; ... % zcG - vCG_c3./-kG <= 0

                    ceq       = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
        end        
      case 'all'
        switch lower(choiceMechType)
          case 'li'
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % L-R-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            % L-B-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            % L-L-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            
            X0 = [z0GX0,z0SX0,zcGX0,zcSX0,vCGX0_c1,vCGX0_c2,vCGX0_c3,vCSX0,vIGX0_c1,vIGX0_c2,vIGX0_c3,t0GX0,t0SX0,seX0,siX0,kGX0,kSX0,wGX0,wSX0];
            tg = {z0Gtg,z0Stg,zcGtg,zcStg,vCGtg_c1,vCGtg_c2,vCGtg_c3,vCStg,vIGtg_c1,vIGtg_c2,vIGtg_c3,t0Gtg,t0Stg,setg,sitg,kGtg,kStg,wGtg,wStg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}

                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,z0SLB,zcGLB,zcSLB,vCGLB,vCGLB,vCGLB,vCSLB,vIGLB,vIGLB,vIGLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB,wGLB,wSLB];
                UB = [z0GUB,z0SUB,zcGUB,zcSUB,vCGUB,vCGUB,vCGUB,vCSUB,vIGUB,vIGUB,vIGUB,t0GUB,t0GUB,seUB,siUB,kGUB,kSUB,wGUB,wSUB];
                
                % Linear constraints
                % ---------------------------------------------------------
                linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG <= 0
                           0 1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                linconB = [0; ...
                           0];
                         
                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) [x(3) - x(5)./-x(16); ...  % zcG - vCG_c1./-kG <= 0
                                      x(3) - x(6)./-x(16); ...  % zcG - vCG_c2./-kG <= 0
                                      x(3) - x(7)./-x(16); ...  % zcG - vCG_c3./-kG <= 0
                                      x(4) - x(8)./-x(17)]; ... % zcS - vCS./-kS <= 0
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c         = @(x) [x(3) - x(5)./-x(16); ...  % zcG - vCG_c1./-kG <= 0
                                      x(3) - x(6)./-x(16); ...  % zcG - vCG_c2./-kG <= 0
                                      x(3) - x(7)./-x(16); ...  % zcG - vCG_c3./-kG <= 0
                                      x(4) - x(8)./-x(17)]; ... % zcS - vCS./-kS <= 0
                    ceq       = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
          case {'race','ffi'}
            switch lower(inhibMechType)
              case 'li'
                % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
                % R-L-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
                % F-L-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
                
                X0 = [z0GX0,z0SX0,zcGX0,zcSX0,vCGX0_c1,vCGX0_c2,vCGX0_c3,vCSX0,vIGX0_c1,vIGX0_c2,vIGX0_c3,t0GX0,t0SX0,seX0,siX0,kGX0,kSX0,wGX0,wSX0];
                tg = {z0Gtg,z0Stg,zcGtg,zcStg,vCGtg_c1,vCGtg_c2,vCGtg_c3,vCStg,vIGtg_c1,vIGtg_c2,vIGtg_c3,t0Gtg,t0Stg,setg,sitg,kGtg,kStg,wGtg,wStg};
                
                switch lower(simGoal)
                  case {'optimize','startvals'}

                    % Bounds
                    % -----------------------------------------------------
                    LB = [z0GLB,z0SLB,zcGLB,zcSLB,vCGLB,vCGLB,vCGLB,vCSLB,vIGLB,vIGLB,vIGLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB,wGLB,wSLB];
                    UB = [z0GUB,z0SUB,zcGUB,zcSUB,vCGUB,vCGUB,vCGUB,vCSUB,vIGUB,vIGUB,vIGUB,t0GUB,t0GUB,seUB,siUB,kGUB,kSUB,wGUB,wSUB];

                    % Linear constraints
                    % -----------------------------------------------------
                    linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG <= 0
                               0 1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                    linconB = [0; ...
                               0];

                    % Nonlinear constraints
                    % -----------------------------------------------------
                    switch lower(solverType)
                      case 'fminsearchcon'
                        % Inequality constraints
                        nonlincon = @(x) [x(3) - x(5)./-x(16); ...  % zcG - vCG_c1./-kG <= 0
                                          x(3) - x(6)./-x(16); ...  % zcG - vCG_c2./-kG <= 0
                                          x(3) - x(7)./-x(16); ...  % zcG - vCG_c3./-kG <= 0
                                          x(4) - x(8)./-x(17)]; ... % zcS - vCS./-kS <= 0
                      case {'fmincon','ga'}
                        % Inequality and equality constraints
                        c         = @(x) [x(3) - x(5)./-x(16); ...  % zcG - vCG_c1./-kG <= 0
                                          x(3) - x(6)./-x(16); ...  % zcG - vCG_c2./-kG <= 0
                                          x(3) - x(7)./-x(16); ...  % zcG - vCG_c3./-kG <= 0
                                          x(4) - x(8)./-x(17)]; ... % zcS - vCS./-kS <= 0            
                        ceq       = @(x) [];

                        nonlincon = @(x) deal(c(x),ceq(x));
                    end
                end
              case {'race','bi'}
                % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
                % R-R-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % R-B-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % F-R-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % F-B-V-A     | 1 | 1 | 1 | 1 | 3 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                
                X0 = [z0GX0,z0SX0,zcGX0,zcSX0,vCGX0_c1,vCGX0_c2,vCGX0_c3,vCSX0,vIGX0_c1,vIGX0_c2,vIGX0_c3,t0GX0,t0SX0,seX0,siX0,kGX0,kSX0];
                tg = {z0Gtg,z0Stg,zcGtg,zcStg,vCGtg_c1,vCGtg_c2,vCGtg_c3,vCStg,vIGtg_c1,vIGtg_c2,vIGtg_c3,t0Gtg,t0Stg,setg,sitg,kGtg,kStg};
                
                switch lower(simGoal)
                  case {'optimize','startvals'}

                    % Bounds
                    % -----------------------------------------------------
                    LB = [z0GLB,z0SLB,zcGLB,zcSLB,vCGLB,vCGLB,vCGLB,vCSLB,vIGLB,vIGLB,vIGLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB];
                    UB = [z0GUB,z0SUB,zcGUB,zcSUB,vCGUB,vCGUB,vCGUB,vCSUB,vIGUB,vIGUB,vIGUB,t0GUB,t0GUB,seUB,siUB,kGUB,kSUB];

                    % Linear constraints
                    % -----------------------------------------------------
                    linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG <= 0
                               0 1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                    linconB = [0; ...
                               0];
                             
                    % Nonlinear constraints
                    % -----------------------------------------------------
                    switch lower(solverType)
                      case 'fminsearchcon'
                        % Inequality constraints
                        nonlincon = @(x) [x(3) - x(5)./-x(16); ...  % zcG - vCG_c1./-kG <= 0
                                          x(3) - x(6)./-x(16); ...  % zcG - vCG_c2./-kG <= 0
                                          x(3) - x(7)./-x(16); ...  % zcG - vCG_c3./-kG <= 0
                                          x(4) - x(8)./-x(17)]; ... % zcS - vCS./-kS <= 0
                      case {'fmincon','ga'}
                        % Inequality and equality constraints
                        c         = @(x) [x(3) - x(5)./-x(16); ...  % zcG - vCG_c1./-kG <= 0
                                          x(3) - x(6)./-x(16); ...  % zcG - vCG_c2./-kG <= 0
                                          x(3) - x(7)./-x(16); ...  % zcG - vCG_c3./-kG <= 0
                                          x(4) - x(8)./-x(17)]; ... % zcS - vCS./-kS <= 0            
                        ceq       = @(x) [];

                        nonlincon = @(x) deal(c(x),ceq(x));
                    end
                end
            end
        end
    end
  case 'zc'
    switch lower(simScope)
      case 'go'
        switch lower(choiceMechType)
          case 'li'
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % L-R-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            % L-B-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            % L-L-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 1 | 0 |
            
            X0 = [z0GX0,zcGX0_c1,zcGX0_c2,zcGX0_c3,vCGX0,vIGX0,t0GX0,seX0,siX0,kGX0,wGX0];
            tg = {z0Gtg,zcGtg_c1,zcGtg_c2,zcGtg_c3,vCGtg,vIGtg,t0Gtg,setg,sitg,kGtg,wGtg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}

                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,zcGLB,zcGLB,zcGLB,vCGLB,vIGLB,t0GLB,seLB,siLB,kGLB,wGLB];
                UB = [z0GUB,zcGUB,zcGUB,zcGUB,vCGUB,vIGUB,t0GUB,seUB,siUB,kGUB,wGUB];
                
                % Linear constraints
                % ---------------------------------------------------------
                linconA = [1 -1 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c1 <= 0
                           1 0 -1 0 0 0 0 0 0 0 0; ... % z0G - zcG_c2 <= 0
                           1 0 0 -1 0 0 0 0 0 0 0];    % z0G - zcG_c3 <= 0
                linconB = [0; ...
                           0; ...
                           0];
                
                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) [x(2) - x(5) ./-x(10); ... % zcG_c1 - vCG./-kG <= 0
                                      x(3) - x(5) ./-x(10); ... % zcG_c2 - vCG./-kG <= 0
                                      x(4) - x(5) ./-x(10)];    % zcG_c3 - vCG./-kG <= 0
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c         = @(x) [x(2) - x(5) ./-x(10); ... % zcG_c1 - vCG./-kG <= 0
                                      x(3) - x(5) ./-x(10); ... % zcG_c2 - vCG./-kG <= 0
                                      x(4) - x(5) ./-x(10)];    % zcG_c3 - vCG./-kG <= 0
                    
                    ceq       = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
          case {'race','ffi'}
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % R-R-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % R-B-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % R-L-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-R-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-B-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            % F-L-Zc-G    | 1 | 0 | 3 | 0 | 1 | 0 | 1 | 1 | 0 | 1 | 1 | 1 | 0 | 0 | 0 |
            
            X0 = [z0GX0,zcGX0_c1,zcGX0_c2,zcGX0_c3,vCGX0,vIGX0,t0GX0,seX0,siX0,kGX0];
            tg = {z0Gtg,zcGtg_c1,zcGtg_c2,zcGtg_c3,vCGtg,vIGtg,t0Gtg,setg,sitg,kGtg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}

                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,zcGLB,zcGLB,zcGLB,vCGLB,vIGLB,t0GLB,seLB,siLB,kGLB];
                UB = [z0GUB,zcGUB,zcGUB,zcGUB,vCGUB,vIGUB,t0GUB,seUB,siUB,kGUB];
                
                % Linear constraints
                % ---------------------------------------------------------
                linconA = [1 -1 0 0 0 0 0 0 0 0; ... % z0G - zcG_c1 <= 0
                           1 0 -1 0 0 0 0 0 0 0; ... % z0G - zcG_c2 <= 0
                           1 0 0 -1 0 0 0 0 0 0];    % z0G - zcG_c3 <= 0
                linconB = [0; ...
                           0; ...
                           0];

                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) [x(2) - x(5) ./-x(10); ... % zcG_c1 - vCG./-kG <= 0
                                      x(3) - x(5) ./-x(10); ... % zcG_c2 - vCG./-kG <= 0
                                      x(4) - x(5) ./-x(10)];    % zcG_c3 - vCG./-kG <= 0
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c         = @(x) [x(2) - x(5) ./-x(10); ... % zcG_c1 - vCG./-kG <= 0
                                      x(3) - x(5) ./-x(10); ... % zcG_c2 - vCG./-kG <= 0
                                      x(4) - x(5) ./-x(10)];    % zcG_c3 - vCG./-kG <= 0
                    
                    ceq       = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
        end        
      case 'all'
        switch lower(choiceMechType)
          case 'li'
            % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
            % L-R-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            % L-B-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            % L-L-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
            
            X0 = [z0GX0,z0SX0,zcGX0_c1,zcGX0_c2,zcGX0_c3,zcSX0,vCGX0,vCSX0,vIGX0,t0GX0,t0SX0,seX0,siX0,kGX0,kSX0,wGX0,wSX0];
            tg = {z0Gtg,z0Stg,zcGtg_c1,zcGtg_c2,zcGtg_c3,zcStg,vCGtg,vCStg,vIGtg,t0Gtg,t0Stg,setg,sitg,kGtg,kStg,wGtg,wStg};
            
            switch lower(simGoal)
              case {'optimize','startvals'}

                % Bounds
                % ---------------------------------------------------------
                LB = [z0GLB,z0SLB,zcGLB,zcGLB,zcGLB,zcSLB,vCGLB,vCSLB,vIGLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB,wGLB,wSLB];
                UB = [z0GUB,z0SUB,zcGUB,zcGUB,zcGUB,zcSUB,vCGUB,vCSUB,vIGUB,t0GUB,t0SUB,seUB,siUB,kGUB,kSUB,wGUB,wSUB];

                % Linear constraints
                % ---------------------------------------------------------
                linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c1 <= 0
                           1 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c2 <= 0
                           1 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c3 <= 0
                           0 1 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                linconB = [0; ...
                           0; ...
                           0; ...
                           0];
                         
                % Nonlinear constraints
                % ---------------------------------------------------------
                switch lower(solverType)
                  case 'fminsearchcon'
                    % Inequality constraints
                    nonlincon = @(x) [x(3) - x(7) ./-x(14); ... % zcG_c1 - vCG./-kG <= 0
                                      x(4) - x(7) ./-x(14); ... % zcG_c2 - vCG./-kG <= 0
                                      x(5) - x(7) ./-x(14); ... % zcG_c3 - vCG./-kG <= 0
                                      x(6) - x(8) ./-x(15)];    % zcS - vCS./-kS <= 0
                  case {'fmincon','ga'}
                    % Inequality and equality constraints
                    c =         @(x) [x(3) - x(7) ./-x(14); ... % zcG_c1 - vCG./-kG <= 0
                                      x(4) - x(7) ./-x(14); ... % zcG_c2 - vCG./-kG <= 0
                                      x(5) - x(7) ./-x(14); ... % zcG_c3 - vCG./-kG <= 0
                                      x(6) - x(8) ./-x(15)];    % zcS - vCS./-kS <= 0
                    
                    ceq = @(x) [];

                    nonlincon = @(x) deal(c(x),ceq(x));
                end
            end
          case {'race','ffi'}
            switch lower(inhibMechType)
              case 'li'
                % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
                % R-L-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
                % F-L-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 |
                
                X0 = [z0GX0,z0SX0,zcGX0_c1,zcGX0_c2,zcGX0_c3,zcSX0,vCGX0,vCSX0,vIGX0,t0GX0,t0SX0,seX0,siX0,kGX0,kSX0,wGX0,wSX0];
                tg = {z0Gtg,z0Stg,zcGtg_c1,zcGtg_c2,zcGtg_c3,zcStg,vCGtg,vCStg,vIGtg,t0Gtg,t0Stg,setg,sitg,kGtg,kStg,wGtg,wStg};
                
                switch lower(simGoal)
                  case {'optimize','startvals'}

                    % Bounds
                    % -----------------------------------------------------
                    LB = [z0GLB,z0SLB,zcGLB,zcGLB,zcGLB,zcSLB,vCGLB,vCSLB,vIGLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB,wGLB,wSLB];
                    UB = [z0GUB,z0SUB,zcGUB,zcGUB,zcGUB,zcSUB,vCGUB,vCSUB,vIGUB,t0GUB,t0SUB,seUB,siUB,kGUB,kSUB,wGUB,wSUB];

                    % Linear constraints
                    % -----------------------------------------------------
                    linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c1 <= 0
                               1 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c2 <= 0
                               1 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c3 <= 0
                               0 1 0 0 0 -1 0 0 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                    linconB = [0; ...
                               0; ...
                               0; ...
                               0];  

                    % Nonlinear constraints
                    % -----------------------------------------------------
                    switch lower(solverType)
                      case 'fminsearchcon'
                        % Inequality constraints
                        nonlincon = @(x) [x(3) - x(7) ./-x(14); ... % zcG_c1 - vCG./-kG <= 0
                                          x(4) - x(7) ./-x(14); ... % zcG_c2 - vCG./-kG <= 0
                                          x(5) - x(7) ./-x(14); ... % zcG_c3 - vCG./-kG <= 0
                                          x(6) - x(8) ./-x(15)];    % zcS - vCS./-kS <= 0
                      case {'fmincon','ga'}
                        % Inequality and equality constraints
                        c =         @(x) [x(3) - x(7) ./-x(14); ... % zcG_c1 - vCG./-kG <= 0
                                          x(4) - x(7) ./-x(14); ... % zcG_c2 - vCG./-kG <= 0
                                          x(5) - x(7) ./-x(14); ... % zcG_c3 - vCG./-kG <= 0
                                          x(6) - x(8) ./-x(15)];    % zcS - vCS./-kS <= 0
                    
                        ceq = @(x) [];

                        nonlincon = @(x) deal(c(x),ceq(x));
                    end
                end
              case {'race','bi'}
                % Model       |z0G|z0S|zcG|zcS|vCG|vCS|vIG|t0G|t0S| se| si| kG| kS| wG| wS|
                % R-R-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % R-B-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % F-R-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                % F-B-Zc-A    | 1 | 1 | 3 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 1 | 0 | 0 |
                
                X0 = [z0GX0,z0SX0,zcGX0_c1,zcGX0_c2,zcGX0_c3,zcSX0,vCGX0,vCSX0,vIGX0,t0GX0,t0SX0,seX0,siX0,kGX0,kSX0];
                tg = {z0Gtg,z0Stg,zcGtg_c1,zcGtg_c2,zcGtg_c3,zcStg,vCGtg,vCStg,vIGtg,t0Gtg,t0Stg,setg,sitg,kGtg,kStg};

                switch lower(simGoal)
                  case {'optimize','startvals'}

                    % Bounds
                    % -----------------------------------------------------
                    LB = [z0GLB,z0SLB,zcGLB,zcGLB,zcGLB,zcSLB,vCGLB,vCSLB,vIGLB,t0GLB,t0SLB,seLB,siLB,kGLB,kSLB];
                    UB = [z0GUB,z0SUB,zcGUB,zcGUB,zcGUB,zcSUB,vCGUB,vCSUB,vIGUB,t0GUB,t0SUB,seUB,siUB,kGUB,kSUB];

                    % Linear constraints
                    % -----------------------------------------------------
                    linconA = [1 0 -1 0 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c1 <= 0
                               1 0 0 -1 0 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c2 <= 0
                               1 0 0 0 -1 0 0 0 0 0 0 0 0 0 0; ... % z0G - zcG_c3 <= 0
                               0 1 0 0 0 -1 0 0 0 0 0 0 0 0 0];    % z0S - zcS <= 0
                    linconB = [0; ...
                               0; ...
                               0; ...
                               0];  

                    % Nonlinear constraints
                    % -----------------------------------------------------
                    switch lower(solverType)
                      case 'fminsearchcon'
                        % Inequality constraints
                        nonlincon = @(x) [x(3) - x(7) ./-x(14); ... % zcG_c1 - vCG./-kG <= 0
                                          x(4) - x(7) ./-x(14); ... % zcG_c2 - vCG./-kG <= 0
                                          x(5) - x(7) ./-x(14); ... % zcG_c3 - vCG./-kG <= 0
                                          x(6) - x(8) ./-x(15)];    % zcS - vCS./-kS <= 0
                      case {'fmincon','ga'}
                        % Inequality and equality constraints
                        c =         @(x) [x(3) - x(7) ./-x(14); ... % zcG_c1 - vCG./-kG <= 0
                                          x(4) - x(7) ./-x(14); ... % zcG_c2 - vCG./-kG <= 0
                                          x(5) - x(7) ./-x(14); ... % zcG_c3 - vCG./-kG <= 0
                                          x(6) - x(8) ./-x(15)];    % zcS - vCS./-kS <= 0

                        ceq = @(x) [];

                        nonlincon = @(x) deal(c(x),ceq(x));
                    end
                end
            end
        end
    end
end