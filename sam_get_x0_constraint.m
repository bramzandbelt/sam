function X = sam_get_x0_constraint(SAM,model)
% SAM_GET_X0_CONSTRAINT Get initial parameter values and parameter
% constraints
%  
% DESCRIPTION 
% Specifies the initial parameter values and bound constraints, linear
% constraints, and nonlinear constraints
%  
% SYNTAX 
% SAM_GET_X0_CONSTRAINT; 
%
% SAM           - structure with job info
% models        - struct, containing fields features and parentsw
%
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Mon 27 Jan 2014 09:44:58 CST by bram 
% $Modified: Mon 27 Jan 2014 09:44:58 CST by bram 

 

% Specify parameter: 
% - number
% - states (free/fixed)
% - indices
% - names
% - initial values
%   * do best-fitting values exist for parent models
%   *
% - bounds


% #. Process inputs
% =========================================================================

features    = model.features;

parents     = model.parents;

nCat        = model.XSpec.n.nCat;

XSpec       =  model.XSpec;

iVe         =  SAM.des.XCat.i.iVe;

className   = {'Go','Stop'};

XCatName    = SAM.des.XCat.name;

nStm        = [6 1];
nRsp        = [6 1];
nCnd        = 3;
nClass      = 2;
iScale      = 7;
nXCat       = SAM.des.XCat.n;

XSpec       =  model.XSpec;


outDir      = SAM.io.outDir;
simScope    = SAM.sim.scope;
choiceMech  = SAM.des.choiceMech.type;
inhibMech   = SAM.des.inhibMech.type;

zLB         = SAM.des.accumMech.zLB;

if isfield(SAM.optim,'X0')
  preSpecX0   = SAM.optim.X0;
else
  preSpecX0   = [];
end

preSpecX0 = 100*randn(1,model.XSpec.n.n);


% Get column indices
% -------------------------------------------------------------------------
iZ0 = SAM.des.XCat.i.iZ0;
iZc = SAM.des.XCat.i.iZc;
iV  = SAM.des.XCat.i.iV;
iK  = SAM.des.XCat.i.iK;

% 1.1.#. Static variables
% =========================================================================

X         = struct('n',[], ...          % Number
                   'free',[], ...       % Status (free or fixed)
                   'i',[], ...          % Indices
                   'name',[], ...       % Names
                   'X0',[], ...         % Initial parameter values
                   'LB',[], ...         % Lower bounds
                   'UB',[], ...         % Upper bounds
                   'linCon',[], ...     % Linear constraints
                   'nonLinCon',[]);     % Nonlinear constraints

% 1.#.#. Dynamic variables
% =========================================================================

taskFactors = [nStm;nRsp;nCnd,nCnd];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. SPECIFY NUMBER OF PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This number is used to compute Bayesian information criterion values
%
%
%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. SPECIFY FREE AND FIXED PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. SPECIFY PARAMETER INDICES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is used by sam_decode_x to convert the parameter vector X into
% individual parameters.
%
%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. X0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The initial parameter value

% Has a parameter vector been specified? If so, use that.
% Is a best-fitting parameter file of a parent model or go model present? 
% If so, take that.
% Else, gauge rough estimates of parameters


% Best-fitting parameter files of present go model
goX0File = arrayfun(@(a) fullfile(outDir,sprintf('bestFValX_%strials_c%s_i%s_model%.3d.mat', ...
                        'go',choiceMech,inhibMech,a)),model.i,'Uni',0);
existGoX0File = any(cellfun(@exist,goX0File(:)) == 2);
                      
% Best-fitting parameter files of parent models
parentX0File = arrayfun(@(a) fullfile(outDir,sprintf('bestFValX_%strials_c%s_i%s_model%.3d.mat', ...
                        simScope,choiceMech,inhibMech,a)),model.parents,'Uni',0);

% Check if any best-fitting parameter file exists
existParentX0File = any(cellfun(@exist,parentX0File(:)) == 2);

if ~isempty(preSpecX0)
  % Starting parameters have been specified
  X0 = preSpecX0;
elseif any(existGoX0File)
  % Go model is present
  X0File = goX0File;
  
  % Load the file with starting values
  X0 = load(X0File);
    
elseif any(existParentX0File)
  % Parent model is present
  X0File = parentX0File(max(find(existParentX0File)));
  
  % Load the file with starting values
  X0 = load(X0File);
else
  
end





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. BOUNDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

XMultiplicative = cell2mat(arrayfun(@(a,b) ones(1,a)*b,nCat,multiplicative,'Uni',0));
XAdditive = cell2mat(arrayfun(@(a,b) ones(1,a)*b,nCat,additive,'Uni',0));

XHardLB = cell2mat(arrayfun(@(a,b) ones(1,a)*b,nCat,hardLB,'Uni',0));
XHardUB = cell2mat(arrayfun(@(a,b) ones(1,a)*b,nCat,hardLB,'Uni',0));


% Set bounds
LB = X0 - X0*diag(XMultiplicative) - XAdditive;
UB = X0 + X0*diag(XMultiplicative) + XAdditive;

% Correct bounds if they cross the hard limits
LB(LB<XHardLB) = XHardLB(LB<XHardLB);
UB(UB>XHardUB) = XHardUB(UB>XHardUB);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. LINEAR CONSTRAINTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Linear constraint array (linConA) and right hand side vector (linConB):
% linConA * X <= linConB
%
% The starting value should be smaller than the threshold (z0 < zc)

linConA = cell(nClass,1);
linConB = cell(nClass,1);

for iClass = 1:nClass
  
  % Pre-allocate linConA and linConB
  linConA{iClass} = zeros(nCombi{iClass},XSpec.n.n);
  linConB{iClass} = zeros(nCombi{iClass},1);
  
  for iCombi = 1:nCombi{iClass}
    linConA{iClass}(iCombi,XSpec.i.iCatClass{iClass,iZ0}(iCombi)) = 1;
    linConA{iClass}(iCombi,XSpec.i.iCatClass{iClass,iZc}(iCombi)) = -1;
  end
  
end

linConA = cell2mat(linConA(:));
linConB = cell2mat(linConB(:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. NONLINEAR CONSTRAINTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% zc - v/-k <= 0

ineqCon = cell(nClass,1);

for iClass = 1:nClass
  
  ineqCon{iClass} = cell(nCombi{iClass},1);
  
  for iCombi = 1:nCombi{iClass}
    
    if numel(X.i.iCatClass{iClass,iZc}) == nCombi{iClass}
      tmpIZc        = num2str(X.i.iCatClass{iClass,iZc}(iCombi));
    elseif numel(X.i.iCatClass{iClass,iZc}) == 1
      tmpIZc        = num2str(X.i.iCatClass{iClass,iZc});
    else
      error(['The number of zc parameters in class %d does not equal ', ...
             'the number of task factor combinations, nor does it ', ...
             'equal one.',iClass]);
    end
    
    if numel(X.i.iCatClass{iClass,iV}) == nCombi{iClass}
      tmpIV        = num2str(X.i.iCatClass{iClass,iV}(iCombi));
    elseif numel(X.i.iCatClass{iClass,iV}) == 1
      tmpIV        = num2str(X.i.iCatClass{iClass,iV});
    else
      error(['The number of v parameters in class %d does not equal ', ...
             'the number of task factor combinations, nor does it ', ...
             'equal one.',iClass]);
    end
    
    if numel(X.i.iCatClass{iClass,iK}) == nCombi{iClass}
      tmpIK        = num2str(X.i.iCatClass{iClass,iK}(iCombi));
    elseif numel(X.i.iCatClass{iClass,iK}) == 1
      tmpIK        = num2str(X.i.iCatClass{iClass,iK});
    else
      error(['The number of k parameters in class %d does not equal ', ...
             'the number of task factor combinations, nor does it ', ...
             'equal one.',iClass]);
    end

    ineqCon{iClass}{iCombi} = ['x(',tmpIZc,') - x(',tmpIV,') ./ -x(',tmpIK,');'];
  end
  
end

ineqCon = vertcat(ineqCon{:});

switch lower(solverType)
  case 'fminsearchcon'
    nonlincon       = str2func(strcat('@(x) [', ineqCon{:}, ']')); % Inequality constraint
  case {'fmincon','ga'}
    c(1)            = str2func(strcat('@(x) [', ineqCon{:}, ']')); % Inequality constraint
    ceq             = @(x) [];                  % Equality constraint
    nonlincon       = @(x) deal(c(x),ceq(x));
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. TAG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

kindCat = cell(1,nXCat);

for iXCat = 1:nXCat
  
  free = freeCat{iXCat};
  
  if XCat.included == 0
    kindCat{iXCat} == 'excluded'
  else
    
    if numel(free) == 1 && free == 1
      kindCat{iXCat} = 'general-free';
    elseif numel(free) == 1 && free == 0
      kindCat{iXCat} = 'general-fixed';
    elseif numel(free) == nClass && all(free) == 1
      kindCat{iXCat} = 'cls-spec-free';
    elseif numel(free) == nClass && any(free) == 1
      kindCat{iXCat} = 'cls-spec-mixed';
    elseif numel(free) == nClass && any(free) == 0
      kindCat{iXCat} = 'cls-spec-fixed';
    elseif numel(free) > nClass && all(free) == 1
      kindCat{iXCat} = 'cls+fact-spec-free';
    elseif numel(free) > nClass && any(free) == 1
      kindCat{iXCat} = 'cls+fact-spec-mixed';
    elseif numel(free) > nClass && any(free) == 0
      kindCat{iXCat} = 'cls+fact-spec-fixed';
    else
      error('Unknown parameter kind');
    end
  end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. SUBFUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [c, sz] = getit(c)
% Extract data from cell arrays containing cell arrays

 if iscell(c)
     d = size(c,2);
     [c, sz] = cellfun(@getit, c, 'UniformOutput', 0);
     c = cat(2,c{:});
     sz = [sz{1} d];
 else
     c = {c};
     sz = [];
 end