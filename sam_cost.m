function cost = sam_cost(X,SAM)
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

nSim = SAM.sim.n;

obs = SAM.optim.obs;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. SIMULATE EXPERIMENT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

prd = sam_sim_expt('optimize',X,SAM);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. COMPUTE COST
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 3.1. Compute cost for correct trials (go correct)
% =========================================================================
[costCorr,prd.pMassCorr] = compute_cost(prd.rtCorr,obs.rtQCorr,obs.fCorr,obs.pMassCorr);

% 3.2. Compute cost for error trials (go error, stop failure)
% =========================================================================
[costError,prd.pMassError] = compute_cost(prd.rtError,obs.rtQError,obs.fError,obs.pMassError);

cost = costCorr + costError;

% sam_plot_obs_prd(SAM,obsOptimData,prdOptimData);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. NESTED FUNCTIONS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

function [cost,pMPCell] = compute_cost(rtP,rtQO,fO,pMO)
  
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
  cost          = sam_chi_square(pMO(iAnyO),pMP(iAnyO),fO(iAnyO));

end
end