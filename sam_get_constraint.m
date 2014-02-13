function sam_get_constraint(SAM)
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
XCat        = SAM.des.XCat;

% Parameter specifics
XSpec       = model.XSpec;

simScope    = SAM.sim.scope;

switch lower(simScope)
  case 'go'
    nClass  = 1;
    nCat = XSpec.n.nCatClass(1,:);
    freeCat = XSpec.free.freeCatClass(1,:);
  case 'all'
    nClass  = 2;
    nCat = XSpec.n.nCat;
    freeCat = XSpec.free.freeCat;
end

% Number of parameters per parameter category
nCat        = model.XSpec.n.nCat;

solverType  = SAM.optim.solver.type;

additive        = SAM.des.XCat.additive;
multiplicative  = SAM.des.XCat.multiplicative;

% Paremeter category column indices
% -------------------------------------------------------------------------
iZ0 = SAM.des.XCat.i.iZ0;
iZc = SAM.des.XCat.i.iZc;
iV  = SAM.des.XCat.i.iV;
iK  = SAM.des.XCat.i.iK;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. BOUNDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Multiplicative and additive factors, for each parameter
XMultiplicative = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,multiplicative,'Uni',0));
XAdditive       = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,additive,'Uni',0));

% Hard lower and upper bounds, , for each parameter
XHardLB         = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,XCat.hardLB,'Uni',0));
XHardUB         = cell2mat(arrayfun(@(in1,in2) ones(1,in1)*in2,nCat,XCat.hardLB,'Uni',0));

% Set bounds
LB              = X0 - X0*diag(XMultiplicative) - XAdditive;
UB              = X0 + X0*diag(XMultiplicative) + XAdditive;

% Correct for crossing hard limits
LB(LB<XHardLB)  = XHardLB(LB<XHardLB);
UB(UB>XHardUB)  = XHardUB(UB>XHardUB);

% Correct for fixed parameters


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
  
  % Pre-allocate linConA and linConB
  A{iClass} = zeros(XSpec.nCombi{iClass},XSpec.n.n);
  b{iClass} = zeros(XSpec.nCombi{iClass},1);
  
  % z0 - zc should be smaller than 0
  for iCombi = 1:XSpec.nCombi{iClass}
    A{iClass}(iCombi,XSpec.i.iCatClass{iClass,iZ0}(iCombi)) = 1;
    A{iClass}(iCombi,XSpec.i.iCatClass{iClass,iZc}(iCombi)) = -1;
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
  
  C{iClass} = cell(XSpec.nCombi{iClass},1);
  
  for iCombi = 1:XSpec.nCombi{iClass}
    
    if numel(X.i.iCatClass{iClass,iZc}) == XSpec.nCombi{iClass}
      tmpIZc        = num2str(X.i.iCatClass{iClass,iZc}(iCombi));
    elseif numel(X.i.iCatClass{iClass,iZc}) == 1
      tmpIZc        = num2str(X.i.iCatClass{iClass,iZc});
    else
      error(['The number of zc parameters in class %d does not equal ', ...
             'the number of task factor combinations, nor does it ', ...
             'equal one.',iClass]);
    end
    
    if numel(X.i.iCatClass{iClass,iV}) == XSpec.nCombi{iClass}
      tmpIV        = num2str(X.i.iCatClass{iClass,iV}(iCombi));
    elseif numel(X.i.iCatClass{iClass,iV}) == 1
      tmpIV        = num2str(X.i.iCatClass{iClass,iV});
    else
      error(['The number of v parameters in class %d does not equal ', ...
             'the number of task factor combinations, nor does it ', ...
             'equal one.',iClass]);
    end
    
    if numel(X.i.iCatClass{iClass,iK}) == XSpec.nCombi{iClass}
      tmpIK        = num2str(X.i.iCatClass{iClass,iK}(iCombi));
    elseif numel(X.i.iCatClass{iClass,iK}) == 1
      tmpIK        = num2str(X.i.iCatClass{iClass,iK});
    else
      error(['The number of k parameters in class %d does not equal ', ...
             'the number of task factor combinations, nor does it ', ...
             'equal one.',iClass]);
    end

    C{iClass}{iCombi} = ['x(',tmpIZc,') - x(',tmpIV,') ./ -x(',tmpIK,');'];
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
% 5. CHECK IF X0 MEETS THE BOUND, LINEAR, AND NONLINEAR CONSTRAINTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. PROCESS OUTPUTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

constraint.bound.LB             = LB;
constraint.bound.UB             = UB;
constraint.linear.A             = A;
constraint.linear.b             = b;
constraint.linear.Aeq           = [];
constraint.linear.beq           = [];
constraint.nonlinear.nonLinCon  = nonLinCon;
constraint.nonlinear.C          = C;
constraint.nonlinear.Ceq        = Ceq;