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

outDir          = SAM.io.outDir;
choiceMech      = SAM.des.choiceMech.type;
inhibMech       = SAM.des.inhibMech.type;
simScope        = SAM.sim.scope;
model           = SAM.des.model;

% 1.2. Define dynamic variables
% =========================================================================

% Check if a file with best-fitting go parameters for present model exists
% -------------------------------------------------------------------------
goFile          = arrayfun(@(a) fullfile(outDir, ...
                  sprintf('bestFValX_%strials_c%s_i%s_model%.3d.mat', ...
                  'go',choiceMech,inhibMech,a)),model.i,'Uni',0);
existGoFile     = any(cellfun(@exist,goFile(:)) == 2);

% Check if a file with best-fitting parameters of parent models exist
% -------------------------------------------------------------------------
parentFile      = arrayfun(@(a) fullfile(outDir, ...
                  sprintf('bestFValX_%strials_c%s_i%s_model%.3d.mat', ...
                  simScope,choiceMech,inhibMech,a)),model.parents,'Uni',0);
existParentFile = any(cellfun(@exist,parentFile(:)) == 2);

% Check if a vector of initial parameters has been pre-specified
% -------------------------------------------------------------------------
if isfield(SAM.optim,'X0')
  preSpecX0     = SAM.optim.X0;
else
  preSpecX0     = [];
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. SPECIFY X0
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isempty(preSpecX0)
  % Starting parameters have been specified
  X0 = preSpecX0;
elseif any(existGoFile)
  % A file with best-fitting go parameters for present model exists
  X0File = goFile;
  X0 = load(X0File);
elseif any(existParentFile)
  % A file with best-fitting parameters of parent models exist
  X0File = parentFile(max(find(existParentFile)));
  X0 = load(X0File);
elseif model.i == 1
  % Present model is the root model
else
  X0 = [];
end