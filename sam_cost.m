function cost = sam_cost(X,SAM,obsOptimData,prdOptimData,VCor,VIncor,S,terminate,blockInput,latInhib)
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
% 2. SIMULATE EXPERIMENT
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

prdOptimData = sam_sim_expt('optimize',X,SAM,VCor,VIncor,S,terminate,blockInput,latInhib,prdOptimData);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. COMPUTE COST
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% #.2.1. Compute probability masses
% -------------------------------------------------------------------------

nSim = SAM.sim.nSim;

nSimCell = num2cell(nSim*ones(size(prdOptimData.P)));

prdOptimData.pM  = cellfun(@(a,b,c) histc(a(:),[-Inf,b,Inf])./c,prdOptimData.rt,obsOptimData.rtQ,nSimCell,'Uni',0);
prdOptimData.pM  = cellfun(@(a) a(1:end-1),prdOptimData.pM,'Uni',0);
prdOptimData.pM  = cellfun(@(a) a(:),prdOptimData.pM,'Uni',0);

% Identify non-empty arrays
iNonEmpty   = cell2mat(cellfun(@(a) ~isempty(a),prdOptimData.pM,'Uni',0));

% Make a double vector of observed trial frequencies
fObs        = cell2mat(obsOptimData.f(iNonEmpty));

% Make a double vector of all observed probability masses
pMObs       = cell2mat(obsOptimData.pM(iNonEmpty));

% Make a double vector of all predicted probability masses
pMPrd       = cell2mat(prdOptimData.pM(iNonEmpty));

% Identify non-zero predicted probabilities masses
iNonZero    = pMPrd ~= 0;

% #.2.#. Compute the cost
% -------------------------------------------------------------------------
cost        = sam_chi_square(pMObs(iNonZero),pMPrd(iNonZero),fObs(iNonZero));

sam_plot_obs_prd(SAM,obsOptimData,prdOptimData);
