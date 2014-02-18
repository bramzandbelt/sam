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

nStm            = SAM.expt.nStm;
nRsp            = SAM.expt.nRsp;
nCnd            = SAM.expt.nCnd;

nXCat           = SAM.model.XCat.n;

% 1.2. Define dynamic variables
% =========================================================================
taskFactors   = [nStm;nRsp;nCnd,nCnd];

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

switch lower(simScope)
  case 'go'
    if any(existParentFile)
            
      % Load the best-fitting parameters from the parent model (with higest index) and convert into a cell array
      load(parentFile{end},'X');
      iParent     = max(modelToFit.parents(:));
      parentModel = SAM.model.variants.tree(iParent);
      XGoParent   = mat2cell(X,1,parentModel.XSpec.n.nCatClass(1,:));
      
      % Set starting values for GO parameters in accordance with best-fitting parameters from paranet model.
      X0Go = cell(1,nXCat);
      iClass = 1;
      levels = taskFactors(:,iClass);
      for iXCat = 1:nXCat
        signatureParent = parentModel.features(:,iXCat,iClass);
        signatureModelToFit = modelToFit.features(:,iXCat,iClass);
        XIn = XGoParent{iXCat};
        XOut = transform_X(XIn,signatureParent,signatureModelToFit,levels);
        X0Go{iXCat} = XOut;
      end
      X0 = cell2mat(X0Go);
    elseif modelToFit.i == 1
      X0 = [];
      error('Not implemented yet');
    else
      X0 = [];
    end
    
  case 'all'
    if any(existGoFile) & any(existParentFile)
      
      % GO parameters: use best-fitting parameters from current model as initial parameters
      load(goFile,'X');
      X0Go = X;
      clear X
      
      % STOP parameters: use best-fitting parameters from parent model (with highest index) as initial parameters
      load(parentFile{end},'X');
      iParent       = max(modelToFit.parents(:));
      parentModel   = SAM.model.variants.tree(iParent);
      XStopParent   = X([parentModel.XSpec.i.iCatClass{2,:}]);
      XStopParent   = mat2cell(XStopParent,1,parentModel.XSpec.n.nCatClass(2,:));
      clear X
      
      % Set starting values for STOP parameters in accordance with best-fitting parameters from parent model.
      X0Stop = cell(1,nXCat);
      iClass = 2;
      levels = taskFactors(:,iClass);
      for iXCat = 1:nXCat
        if ~isempty(XStopParent{iXCat})
          signatureParent = parentModel.features(:,iXCat,iClass);
          signatureModelToFit = modelToFit.features(:,iXCat,iClass);
          XIn = XStopParent{iXCat};
          XOut = transform_X(XIn,signatureParent,signatureModelToFit,levels);
          X0Stop{iXCat} = XOut;
        end
      end
      X0Stop = cell2mat(X0Stop);
      
      % Fill in X
      X0 = nan(1,modelToFit.XSpec.n.n);
      X0([modelToFit.XSpec.i.iCatClass{1,:}]) = X0Go;
      X0([modelToFit.XSpec.i.iCatClass{2,:}]) = X0Stop;
      
    elseif any(existParentFile)
      X0 = [];
      error('Not implemented yet');
    elseif modelToFit.i == 1
      X0 = [];
      error('Not implemented yet');
    else
      X0 = [];
      error('No go file or parent file detected for model %d. Initial parameters have not been set.',modelToFit.i);
    end
end
    
function XOut = transform_X(XIn,signatureParent,signatureModelToFit,levels)
  
  
  % #.#.#. Force all inputs to be row vectors
  % -------------------------------------------------------------------------
  XIn                 = XIn(:)';
  levels              = levels(:)';
  signatureParent     = signatureParent(:)';
  signatureModelToFit = signatureModelToFit(:)';
  
  % Experimental factor levels
  l1 = levels(1);
  l2 = levels(2);
  l3 = levels(3);
  
  % Transform X vector from parent model to a 3D matrix (l1xl2xl3)
  if isequal(signatureParent,[0 0 0])
    XVec2Mat  = reshape(repmat(XIn,[l1 l2 l3]),[l1 l2 l3]);        
  elseif isequal(signatureParent,[1 0 0])
    XVec2Mat  = repmat(diag(XIn)*ones(l1,l2),[1 1 l3]);
  elseif isequal(signatureParent,[0 1 0])
    XVec2Mat  = repmat(ones(l1,l2)*diag(XIn),[1 1 l3]);
  elseif isequal(signatureParent,[0 0 1])
    XVec2Mat  = repmat(ones(l1*l2,1),1,l3)*diag(XIn);
    XVec2Mat  = reshape(XVec2Mat,l1,l2,l3);
  elseif isequal(signatureParent,[1 1 0])
    XVec2Mat  = repmat(diag(XIn)*ones(l1*l2,1),1,l3);
    XVec2Mat  = reshape(XVec2Mat,l1,l2,l3);
  elseif isequal(signatureParent,[1 0 1])
    XVec2Mat  = repmat(reshape(XIn,[l1,l3]),l2,1);
    XVec2Mat  = reshape(XVec2Mat,l1,l2,l3);
  elseif isequal(signatureParent,[0 1 1])
    XVec2Mat  = repmat(XIn,l1,1);
    XVec2Mat  = reshape(XVec2Mat,l1,l2,l3);
  elseif isequal(signatureParent,[1 1 1])
    XVec2Mat  = reshape(XIn,[l1 l2 l3]);
  else
    error('Invalid signatureParent');
  end
  
  
  % Now compute from this 3D matrix, the output vector XOut correspodning to the signature of the model to fit
  if isequal(signatureModelToFit,[0 0 0])
    XOut    = nanmean(nanmean(nanmean(XVec2Mat,3),2),1);
  elseif isequal(signatureModelToFit,[1 0 0])
    XOut    = reshape(nanmean(nanmean(XVec2Mat,3),2),1,l1);
  elseif isequal(signatureModelToFit,[0 1 0])
    XOut    = reshape(nanmean(nanmean(XVec2Mat,2),1),1,l2);
  elseif isequal(signatureModelToFit,[0 0 1])
    XOut    = reshape(nanmean(nanmean(XVec2Mat,2),1),1,l3);
  elseif isequal(signatureModelToFit,[1 1 0])
    XOut    = reshape(nanmean(XVec2Mat,3),1,l2*l3);
  elseif isequal(signatureModelToFit,[1 0 1])
    XOut    = reshape(nanmean(XVec2Mat,2),1,l1*l3);
  elseif isequal(signatureModelToFit,[0 1 1])
    XOut    = reshape(nanmean(XVec2Mat,1),1,l2*l3);
  elseif isequal(signatureModelToFit,[1 1 1])
    XOut    = reshape(XVec2Mat,1,l1*l2*l3);
  else
    error('Invalid signatureModelToFit');
  end
  
  XOut = XOut(:)';
  
  
end
end