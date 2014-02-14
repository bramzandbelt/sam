function X0 = sam_get_x0(SAM)
% SAM_GET_X0 Get initial parameters for optimization
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% X0 = SAM_GET_X0(SAM,model); 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Wed 12 Feb 2014 13:23:46 CST by bram 
% $Modified: Wed 12 Feb 2014 13:23:46 CST by bram 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND DEFINE VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Process inputs
% =========================================================================

workDir         = SAM.io.workDir;
modelToFit      = SAM.model.variants.toFit;
modelCatTag     = SAM.model.general.modelCatTag;
simScope        = SAM.sim.scope;

% 1.2. Define dynamic variables
% =========================================================================

% Check if a file with best-fitting go parameters for present model exists
% -------------------------------------------------------------------------
goFile          = sprintf('bestFValX_%s_%strials_model%.3d.mat', ...
                  modelCatTag,'go',modelToFit.i);
existGoFile     = exist(goFile) == 2;

% Check if a file with best-fitting parameters of parent models exist
% -------------------------------------------------------------------------
parentFile      = arrayfun(@(a) fullfile(workDir, ...
                  sprintf('bestFValX_%s_%strials_model%.3d.mat', ...
                  modelCatTag,simScope,a)),modelToFit.parents,'Uni',0);
existParentFile = any(cellfun(@exist,parentFile(:)) == 2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. SPECIFY X0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if any(existGoFile)
  % A file with best-fitting go parameters for present model exists
  X0Go = load(goFile);
elseif any(existParentFile)
  % A file with best-fitting parameters of parent models exist
  X0File = parentFile(max(find(existParentFile)));
  X0 = load(X0File);
elseif modelToFit.i == 1
  % Present model is the root node
else
  X0 = [];
  error('No go file or parent file detected for model %d. Initial parameters have not been set.',modelToFit.i);
end