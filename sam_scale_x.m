function sam_scale_x(subj,dt,trialVar,simScope,architecture,model,fileStr);
% SAM_SCALE_X <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% SAM_SCALE_X; 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Mon 07 Jul 2014 09:47:05 CDT by bram 
% $Modified: Mon 07 Jul 2014 09:47:05 CDT by bram 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1.1. Process inputs
% =========================================================================

if trialVar
  trialVarStr = 'trialvar';
else
  trialVarStr = 'notrialvar';
end

% Static variables
% =========================================================================

% RT quantiles used for computing the scaling factor
rtQ = (.05:.01:.95)';

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Load allFValBestX-file
ds = dataset('File',fullfile(sprintf(fileStr.root,subj,dt,trialVarStr,architecture), ...
                    sprintf(fileStr.bestX,model)))

% Extract BestX parameters and identify them
iBestX          = cell2mat(cellfun(@(in1) ~isempty(regexp(in1,'^BestX.*', 'once')),ds.Properties.VarNames,'Uni',0));
X               = double(ds(1,iBestX));

% Load SAM
load(fullfile(sprintf(fileStr.root,subj,dt,trialVarStr,architecture), ...
              sprintf(fileStr.SAM,model)));   

% Compute model predictions and costs with original time step size
[costDtOrig,altCostDtOrig,prdDtOrig]    = sam_cost(X,SAM);

% Compute model predictions and costs with time step size of 1
SAM.model.accum.dt                      = 1;
[costDt1,altCostDt1,prdDt1]             = sam_cost(X,SAM);

% Compute the scaling factor
% =========================================================================

% Identify GoCCorr trials
% -------------------------------------------------------------------------
% Heuristic: only cells with at least 100 trials are used
iGoCCorr            = cell2mat(cellfun(@(in1) numel(in1) > 100, ...
                                       prdDtOrig.rtGoCCorr, ...
                                       'Uni',0));

% Identify StopIErrorCCorr trials
% -------------------------------------------------------------------------
% Heuristic: only cells with at least 100 trials are used
iStopIErrorCCorr    = cell2mat(cellfun(@(in1) numel(in1) > 100, ...
                                         prdDtOrig.rtStopIErrorCCorr, ...
                                         'Uni',0));

% Compute the scaling
B1                  = cell2mat(cellfun(@(in1,in2) regress(quantile(in1,rtQ),quantile(in2,rtQ)), ...
                                         prdDtOrig.rtGoCCorr(iGoCCorr), ...
                                         prdDt1.rtGoCCorr(iGoCCorr), ...
                                         'Uni',0));
                                     
B2                  = cell2mat(cellfun(@(in1,in2) regress(quantile(in1,rtQ),quantile(in2,rtQ)), ...
                                         prdDtOrig.rtStopIErrorCCorr(iStopIErrorCCorr), ...
                                         prdDt1.rtStopIErrorCCorr(iStopIErrorCCorr), ...
                                         'Uni',0));
scalingFactor = median([B1;B2]);

% Scale parameters
% =========================================================================
XScaled = nan(size(X));

% Starting point
% -------------------------------------------------------------------------
iXCat       = SAM.model.XCat.i.iZ0;
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Threshold
% -------------------------------------------------------------------------
iXCat       = SAM.model.XCat.i.iZc;
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Rate
% -------------------------------------------------------------------------
iXCat       = SAM.model.XCat.i.iV;
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Error rate
% -------------------------------------------------------------------------
iXCat       = SAM.model.XCat.i.iVe;
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Between-trial standard deviation of rate
% -------------------------------------------------------------------------
% This is not described in Brown, Ratcliff, and Smith (2006) and needs to
% be checked.
iXCat       = SAM.model.XCat.i.iEta
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Non-decision time
% -------------------------------------------------------------------------
iXCat       = SAM.model.XCat.i.iT0;
scaleFun    = @(in1,in2,in3) in1(in2)./in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Extrinsic noise
% -------------------------------------------------------------------------
% This is not described in Brown, Ratcliff, and Smith (2006) and needs to
% be checked.
iXCat       = SAM.model.XCat.i.iSe;
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Intrinsic noise
% -------------------------------------------------------------------------
% This parameter should be scaled by the square root of the scaling factor,
% according to Brown, Ratcliff, and Smith (2006). I choose to keep it fixed
% and fit the other parameters, because the intrinsic noise parameter is
% the fixed parameter and I want to keep it the same across all subjects
iXCat       = SAM.model.XCat.i.iSi;
scaleFun    = @(in1,in2,in3) in1(in2).*sqrt(in3);
XScaled     = scale_x(SAM,X,XScaled,1,model,iXCat,simScope,scaleFun);

% Leakage
% -------------------------------------------------------------------------
iXCat       = SAM.model.XCat.i.iK;
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);

% Lateral inhibition
% -------------------------------------------------------------------------
iXCat       = SAM.model.XCat.i.iW;
scaleFun    = @(in1,in2,in3) in1(in2).*in3;
XScaled     = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun);


% Compute (and compare?) the cost
[costDt1XScaled,altCostDt1XScaled,prdDt1XScaled]    = sam_cost(XScaled,SAM);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% NESTED FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function XScaled = scale_x(SAM,X,XScaled,scalingFactor,model,iXCat,simScope,scaleFun)
% INPUTS
% iXCat
% simScope
% X
% XScaled
% scaleFun

if SAM.model.XCat.classSpecific(iXCat)
    switch lower(simScope)
        case 'go'
            % Scale the GO parameter
            iX = SAM.model.variants.tree(model).XSpec.i.go.iCatClass{iXCat};
            XScaled(iX) = scaleFun(X,iX,scalingFactor);
        case 'all'
            % Scale the GO parameter
            iX = SAM.model.variants.tree(model).XSpec.i.all.iCatClass{1,iXCat};
            XScaled(iX) = scaleFun(X,iX,scalingFactor);
            
            % Scale the STOP parameter
            iX = SAM.model.variants.tree(model).XSpec.i.all.iCatClass{2,iXCat};
            XScaled(iX) = scaleFun(X,iX,scalingFactor);
    end
else
    switch lower(simScope)
        case 'go'
            % Scale the parameter
            iX = SAM.model.variants.tree(model).XSpec.i.go.iCatClass{iXCat};
            XScaled(iX) = scaleFun(X,iX,scalingFactor);
        case 'all'
            % Scale the parameter
            iX = SAM.model.variants.tree(model).XSpec.i.all.iCatClass{1,iXCat};
            XScaled(iX) = scaleFun(X,iX,scalingFactor);
    end
end
