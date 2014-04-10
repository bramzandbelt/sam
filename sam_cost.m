function [cost,altCost,prd] = sam_cost(X,SAM)
% SAM_COST <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% SAM_COST; 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Sat 21 Sep 2013 19:43:58 CDT by bram 
% $Modified: Sat 21 Sep 2013 19:47:47 CDT by bram

 
% CONTENTS 
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
nSim      = SAM.sim.n;
simScope  = SAM.sim.scope;
obs       = SAM.optim.obs;
costStat  = SAM.optim.cost.stat.stat;

switch lower(simScope)
  case 'go'
    nFree     =  sum([SAM.model.variants.toFit.XSpec.free.freeCatClass{1,:}]);
  case 'all'
    nFree     = sum(SAM.model.variants.toFit.XSpec.free.free);
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. SIMULATE EXPERIMENT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

prd = sam_sim_expt('optimize',X,SAM);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. COMPUTE COST
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 3.1. Compute cost for correct trials (go correct)
% =========================================================================
[bicCor,chiSquareCorr,prd.pMassCorr] = compute_cost(prd.rtCorr,obs.rtQCorr,obs.fCorr,obs.pMassCorr,nFree);

% 3.2. Compute cost for error trials (go error, stop failure)
% =========================================================================
[bicError,chiSquareError,prd.pMassError] = compute_cost(prd.rtError,obs.rtQError,obs.fError,obs.pMassError,nFree);

switch lower(costStat)
  case 'bic'
    cost    = bicCor + bicError;
    altCost = chiSquareCorr + chiSquareError;
  case 'chisquare'
    cost    = chiSquareCorr + chiSquareError;
    altCost = bicCor + bicError;
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. NESTED FUNCTIONS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

function [bic,chiSquare,pMPCell] = compute_cost(rtP,rtQO,fO,pMO,nFree)
  
  nSimCell      = num2cell(nSim*ones(numel(rtP),1));
  
  % Compute predicted probability mass for each trial category
  pMPCell       = cellfun(@(a,b,c) histc(a(:),[-Inf,b,Inf])./c,rtP,rtQO,nSimCell,'Uni',0);
  pMPCell       = cellfun(@(a) a(1:end-1),pMPCell,'Uni',0);
  pMPCell       = cellfun(@(a) a(:),pMPCell,'Uni',0);
  
  % Identify non-empty arrays
  iNonEmpty     = cell2mat(cellfun(@(a) ~isempty(a),pMPCell,'Uni',0));
  
  % Make a double vector of observed trial frequencies
  fO            = cell2mat(fO(iNonEmpty));

  % Make a double vector of all observed probability masses
  pMO           = cell2mat(pMO(iNonEmpty));

  % Make a double vector of all predicted probability masses
  pMP           = cell2mat(pMPCell(iNonEmpty));

  % Add a small value to bins with a probablity mass of 0 (to prevent
  % division by 0 and hampering optimization)
  pMP(pMP == 0) = 0.001;

  % Identify bins with observations
  iAnyO         = fO > 0;

  % #.2.#. Compute the cost
  % -------------------------------------------------------------------------
  chiSquare     = sam_chi_square(pMO(iAnyO),pMP(iAnyO),fO(iAnyO));
  bic           = sam_bic(pMO(iAnyO),pMP(iAnyO),fO(iAnyO),nFree);
  
end
end