function SAM = sam_spec_job_specific(SAM,iModel);
% SAM_SPEC_JOB_SPECIFIC <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% SAM_SPEC_JOB_SPECIFIC; 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Mon 17 Mar 2014 15:05:32 CDT by bram 
% $Modified: Mon 17 Mar 2014 15:05:32 CDT by bram 

% Go to work directory
cd(SAM.io.workDir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 1. MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Specify the model to be fit
SAM.model.variants.toFit      = SAM.model.variants.tree(iModel);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. OPTIMIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Categorize the observations into categories corresponding with the model specifics
% =========================================================================================================================
SAM.optim.obs                 = sam_categorize_data(SAM);

% Specify initial parameters, based on which parameter constraints are defined
% =========================================================================================================================
SAM.optim.x0Base              = sam_get_x0(SAM);

% Specify parameter constraints
% =========================================================================================================================
SAM.optim.constraint          = sam_get_constraint(SAM);

% Sample 20 uniformly distributed starting points, given constraints
% =========================================================================================================================
nStartPoint                   = SAM.optim.nStartPoint;

LB                            = SAM.optim.constraint.bound.LB;
UB                            = SAM.optim.constraint.bound.UB;
A                             = SAM.optim.constraint.linear.A;
b                             = SAM.optim.constraint.linear.b;
nonLinCon                     = SAM.optim.constraint.nonlinear.nonLinCon;

SAM.optim.x0                  = [SAM.optim.x0Base; ...
                                sam_sample_uniform_constrained_x0(nStartPoint,LB,UB,A,b,nonLinCon,SAM.optim.solver.type)];

% Model predictions
% =========================================================================================================================
nTrialCat                     = size(SAM.optim.obs,1);
SAM.optim.prd                 = dataset({cell(nTrialCat,1),'trialCat'}, ...
                                        {cell(nTrialCat,1),'funGO'}, ...
                                        {cell(nTrialCat,1),'funSTOP'}, ...
                                        {cell(nTrialCat,1),'onset'}, ...
                                        {cell(nTrialCat,1),'duration'}, ...
                                        {nan(nTrialCat,1),'ssd'}, ...
                                        {nan(nTrialCat,1),'nTotal'}, ...
                                        {nan(nTrialCat,1),'nCorr'}, ...
                                        {nan(nTrialCat,1),'nError'}, ...
                                        {nan(nTrialCat,1),'pTotal'}, ...
                                        {nan(nTrialCat,1),'pCorr'}, ...
                                        {nan(nTrialCat,1),'pError'}, ...
                                        {cell(nTrialCat,1),'rtCorr'}, ...
                                        {cell(nTrialCat,1),'rtError'}, ...
                                        {cell(nTrialCat,1),'rtQCorr'}, ...
                                        {cell(nTrialCat,1),'rtQError'}, ...
                                        {cell(nTrialCat,1),'fCorr'}, ...
                                        {cell(nTrialCat,1),'fError'}, ...
                                        {cell(nTrialCat,1),'pMassCorr'}, ...
                                        {cell(nTrialCat,1),'pMassError'}, ...
                                        {cell(nTrialCat,1),'pDefectiveCorr'}, ...
                                        {cell(nTrialCat,1),'pDefectiveError'}, ...
                                        {cell(nTrialCat,1),'modelMat'}, ...
                                        {cell(nTrialCat,1),'dyn'});
SAM.optim.prd.trialCat        = SAM.optim.obs.trialCat;
SAM.optim.prd.onset           = SAM.optim.obs.onset;
SAM.optim.prd.duration        = SAM.optim.obs.duration;
SAM.optim.prd.ssd             = SAM.optim.obs.ssd;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. HACKS (TO BE IMPLEMENTED ELSEWHERE SOON)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dataset array
modelMat                            = dataset({cell(nTrialCat,1),'trialCat'}, ...
                                              {cell(nTrialCat,1),'iTarget'}, ...
                                              {cell(nTrialCat,1),'iNonTarget'}, ...
                                              {cell(nTrialCat,1),'exoConn'});
modelMat.trialCat                   = SAM.optim.obs.trialCat;


iGoTrial                            = cell2mat(cellfun(@(inp1) ~isempty(regexp(inp1,'^goTrial')),modelMat.trialCat,'Uni',0));
iStopTrial                          = cell2mat(cellfun(@(inp1) ~isempty(regexp(inp1,'^stopTrial')),modelMat.trialCat,'Uni',0));
iTargetGoTrial                      = cellfun(@(inp1) logical(inp1(:)),{[0 0 1 0 0 0] [0]},'Uni',0);
iTargetStopTrial                    = cellfun(@(inp1) logical(inp1(:)),{[0 0 1 0 0 0] [1]},'Uni',0);
modelMat.iTarget(iGoTrial)          = cellfun(@(inp1) iTargetGoTrial,modelMat.iTarget(iGoTrial),'Uni',0);
modelMat.iTarget(iStopTrial)        = cellfun(@(inp1) iTargetStopTrial,modelMat.iTarget(iStopTrial),'Uni',0);
iNonTargetC1                        = cellfun(@(inp1) logical(inp1(:)),{[0 0 0 1 0 0] [0]},'Uni',0);
iNonTargetC2                        = cellfun(@(inp1) logical(inp1(:)),{[0 1 0 1 1 0] [0]},'Uni',0);
iNonTargetC3                        = cellfun(@(inp1) logical(inp1(:)),{[1 1 0 1 1 1] [0]},'Uni',0);
iC1                                 = cell2mat(cellfun(@(inp1) ~isempty(regexp(inp1,'GO:c1')),modelMat.trialCat,'Uni',0));
iC2                                 = cell2mat(cellfun(@(inp1) ~isempty(regexp(inp1,'GO:c2')),modelMat.trialCat,'Uni',0));
iC3                                 = cell2mat(cellfun(@(inp1) ~isempty(regexp(inp1,'GO:c3')),modelMat.trialCat,'Uni',0));
modelMat.iNonTarget(iC1)            = cellfun(@(inp1) iNonTargetC1,modelMat.iTarget(iC1),'Uni',0);
modelMat.iNonTarget(iC2)            = cellfun(@(inp1) iNonTargetC2,modelMat.iTarget(iC2),'Uni',0);
modelMat.iNonTarget(iC3)            = cellfun(@(inp1) iNonTargetC3,modelMat.iTarget(iC3),'Uni',0);

% Feed-forward inhibition weight
exoConn                             = cell(nTrialCat,1);

for i = 1:nTrialCat
  iTargetNonTarget = cellfun(@(inp1,inp2) inp1 + inp2,modelMat.iTarget{i},modelMat.iNonTarget{i},'Uni',0);
  switch lower(SAM.model.mat.exoConn.w)
    case 'normalized'
      wFFI = cellfun(@(inp1) -1./(sum(inp1)-1),iTargetNonTarget,'Uni',0);
      wFFI(cellfun(@isinf,wFFI)) = {1};
    otherwise
      wFFI = {0 0};
  end
  thisExoConn = cellfun(@(inp1,inp2) inp1 * (inp2(:) * inp2(:)' - diag(inp2(:))) + diag(inp2(:)),wFFI,iTargetNonTarget,'Uni',0);
  exoConn{i}  = blkdiag(thisExoConn{:});  
end

modelMat.exoConn                    = exoConn;

SAM.optim.modelMat                  = modelMat;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. SAVE THE MODEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

