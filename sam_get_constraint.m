function constraint = sam_get_constraint(SAM)
% SAM_GET_CONSTRAINT <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% SAM_GET_CONSTRAINT; 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
% http://en.wikipedia.org/wiki/Linear_inequality
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Wed 12 Feb 2014 13:25:52 CST by bram 
% $Modified: Wed 12 Feb 2014 13:25:52 CST by bram 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. PROCESS INPUTS AND DEFINE VARIABLES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1.1. Process inputs
% =========================================================================




% Parameter category specifics
XCat        = SAM.model.XCat;

% Parameter specifics
XSpec       = SAM.model.variants.toFit.XSpec;

simScope    = SAM.sim.scope;


nStm            = SAM.expt.nStm;
nRsp            = SAM.expt.nRsp;
nCnd            = SAM.expt.nCnd;

switch lower(simScope)
  case 'go'
    nClass  = 1;
    nCat    = XSpec.n.nCatClass(1,:);
    
    iCatClass = XSpec.i.go.iCatClass;
    
    free    = cell2mat(XSpec.free.freeCatClass(1,:));
  case 'all'
    nClass  = 2;
    nCat    = XSpec.n.nCat;
    
    iCatClass = XSpec.i.all.iCatClass;
    
    free    = XSpec.free.free;
    % Set GO parameters to fixed parameters
    free([iCatClass{1,:}]) = false;
end

solverType  = SAM.optim.solver.type;

additive        = SAM.model.XCat.additive;
multiplicative  = SAM.model.XCat.multiplicative;

X0          = SAM.optim.x0Base;

modelToFit      = SAM.model.variants.toFit;

% Parameter category column indices
% -------------------------------------------------------------------------
iZ0 = SAM.model.XCat.i.iZ0;
iZc = SAM.model.XCat.i.iZc;
iV  = SAM.model.XCat.i.iV;
iK  = SAM.model.XCat.i.iK;

% 1.2. Define dynamic variables
% =========================================================================
taskFactors   = [nStm;nRsp;nCnd,nCnd];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. BOUNDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Multiplicative and additive factors, for each parameter
XMultiplicative = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,multiplicative,'Uni',0));
XAdditive       = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,additive,'Uni',0));

% Hard lower and upper bounds, , for each parameter
XHardLB         = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,XCat.hardLB,'Uni',0));
XHardUB         = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,XCat.hardUB,'Uni',0));

% Set bounds
LB              = X0 - X0*diag(XMultiplicative) - XAdditive;
UB              = X0 + X0*diag(XMultiplicative) + XAdditive;

% Correct for crossing hard limits
LB(LB<XHardLB)  = XHardLB(LB<XHardLB);
UB(UB>XHardUB)  = XHardUB(UB>XHardUB);

% Correct for fixed parameters
LB(~free)       = X0(~free);
UB(~free)       = X0(~free);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. LINEAR CONSTRAINTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Linear equality and inequality constraints

% Linear inequality A*X <= b
% Linear equality Aeq*X = beq

%
% X is a [...] vector of parameter values
% A is an mxn matrix
% b is an mx1 column vector of constants

% Linear constraint array (linConA) and right hand side vector (linConB):
% linConA * X <= linConB
%
% The starting value should be smaller than the threshold (z0 < zc)
A = cell(nClass,1);
b = cell(nClass,1);

for iClass = 1:nClass
  
  nCombiZ0 = diag(taskFactors(:,iClass)) * any(modelToFit.features(:,iZ0,iClass),2);
  nCombiZ0(nCombiZ0 == 0) = 1;
  nCombiZ0 = prod(nCombiZ0);
  
  nCombiZc = diag(taskFactors(:,iClass)) * any(modelToFit.features(:,iZc,iClass),2);
  nCombiZc(nCombiZc == 0) = 1;
  nCombiZc = prod(nCombiZc);
  
  nCombi = max([nCombiZ0,nCombiZc]);
  combiLevels = fullfact([nCombiZ0,nCombiZc]);
  
  % Pre-allocate linConA and linConB
  A{iClass} = zeros(nCombi,sum(nCat));
  b{iClass} = zeros(nCombi,1);
  
  % z0 - zc should be smaller than 0
  for iCombi = 1:nCombi
    A{iClass}(iCombi,iCatClass{iClass,iZ0}(combiLevels(iCombi,1))) = 1;
    A{iClass}(iCombi,iCatClass{iClass,iZc}(combiLevels(iCombi,2))) = -1;
  end
  
end

A = cell2mat(A(:));
b = cell2mat(b(:));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. NONLINEAR CONSTRAINTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Nonlinear equality and inequality constraints

% zc - v/-k <= 0

% C(X)<=0 and Ceq(X)=0

C = cell(nClass,1);

for iClass = 1:nClass
    
  nCombiZc = diag(taskFactors(:,iClass)) * any(modelToFit.features(:,iZc,iClass),2);
  nCombiZc(nCombiZc == 0) = 1;
  nCombiZc = prod(nCombiZc);
  
  nCombiV = diag(taskFactors(:,iClass)) * any(modelToFit.features(:,iV,iClass),2);
  nCombiV(nCombiV == 0) = 1;
  nCombiV = prod(nCombiV);
  
  nCombiK = diag(taskFactors(:,iClass)) * any(modelToFit.features(:,iK,iClass),2);
  nCombiK(nCombiK == 0) = 1;
  nCombiK = prod(nCombiK);
  
  nCombi = max([nCombiZc,nCombiV,nCombiK]);
  combiLevels = fullfact([nCombiZc,nCombiV,nCombiK]);
  
  C{iClass} = cell(nCombi,1);
  
  for iCombi = 1:nCombi
    
    tmpIZc = iCatClass{iClass,iZc}(combiLevels(iCombi,1));
    tmpIV = iCatClass{iClass,iV}(combiLevels(iCombi,2));
    tmpIK = iCatClass{iClass,iK}(combiLevels(iCombi,3));
    
    C{iClass}{iCombi} = ['x(',num2str(tmpIZc),') - x(',num2str(tmpIV),') ./ -x(',num2str(tmpIK),');'];
    
  end
  
end

C = vertcat(C{:});

switch lower(solverType)
  case 'fminsearchcon'
    nonLinCon       = str2func(strcat('@(x) [', C{:}, ']')); % Inequality constraint
  case {'fmincon','ga'}
    C(1)            = str2func(strcat('@(x) [', C{:}, ']')); % Inequality constraint
    Ceq             = @(x) [];                  % Equality constraint
    nonLinCon       = @(x) deal(C(x),Ceq(x));
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. PROCESS OUTPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

constraint.bound.LB             = LB;
constraint.bound.UB             = UB;
constraint.linear.A             = A;
constraint.linear.b             = b;
constraint.linear.Aeq           = [];
constraint.linear.beq           = [];
switch lower(solverType)
  case 'fminsearchcon'
    constraint.nonlinear.nonLinCon  = nonLinCon;
  case {'fmincon','ga'}
    constraint.nonlinear.nonLinCon  = nonLinCon;
    constraint.nonlinear.C          = C;
    constraint.nonlinear.Ceq        = Ceq;
end