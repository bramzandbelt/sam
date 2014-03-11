function [endoConn,extrMod,exoConn,intrMod,V,SE,SI,Z0,ZC,T0] = ...
          sam_decode_x(SAM,X,iTrial)
% function [endoConn,extrMod,exoConn,intrMod,V,SE,SI,Z0,ZC,accumOns] = ...
%           sam_decode_x(SAM,X,iTrial)
% SAM_DECODE_X <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% SAM_DECODE_X; 
%  
% EXAMPLES 
%  
%  
% REFERENCES 
%  
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Fri 23 Aug 2013 11:47:36 CDT by bram 
% $Modified: Fri 23 Aug 2013 11:47:36 CDT by bram 

 
% CONTENTS 
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Process inputs
% ========================================================================= 

% Column indices
iZ0       = SAM.model.XCat.i.iZ0;
iZc       = SAM.model.XCat.i.iZc;
iV        = SAM.model.XCat.i.iV;
iVe       = SAM.model.XCat.i.iVe;
iT0       = SAM.model.XCat.i.iT0;
iSe       = SAM.model.XCat.i.iSe;
iSi       = SAM.model.XCat.i.iSi;
iK        = SAM.model.XCat.i.iK;
iW        = SAM.model.XCat.i.iW;

simScope  = SAM.sim.scope;

switch lower(simScope)
  case 'go'
    N         = SAM.expt.nRsp(1);
    M         = SAM.expt.nStm(1);
  case 'all'
    N         = SAM.expt.nRsp;
    M         = SAM.expt.nStm;
end

trialCat    = SAM.optim.obs.trialCat{iTrial};
stmOns      = SAM.optim.obs.onset{iTrial};
stmDur      = SAM.optim.obs.duration{iTrial};

iTarget     = SAM.optim.modelMat.iTarget{iTrial};
iNonTarget  = SAM.optim.modelMat.iNonTarget{iTrial};
exoConn     = SAM.optim.modelMat.exoConn{iTrial};

% #.#.#. Model matrices
% -------------------------------------------------------------------------------------------------------------------------
endoConn  = SAM.model.mat.endoConn;

% 1.2. Specify dynamic variables
% ========================================================================= 

trueN = arrayfun(@(x) true(x,1),N,'Uni',0);
trueM = arrayfun(@(x) true(x,1),M,'Uni',0);

% Parse trial type 
if ~isempty(regexp(trialCat,'^goTrial_', 'once'))
  token = regexp(trialCat,'goTrial_(\S*)','tokens');
  tagGO   = token{1}{1};
elseif ~isempty(regexp(trialCat,'^stopTrial_', 'once'))
  token = regexp(trialCat,'stopTrial_ssd(\w*)_(\S*)_(\S*)','tokens');
%   tagSsd  = str2double(token{1}{1});
  tagGO   = token{1}{2};
  tagSTOP = token{1}{3};
end

% 1.2.1. Parameter indices per task factor
% -------------------------------------------------------------------------------------------------------------------------
% Specifies which specific index we need per task factor and accumulator category. A nan means no specific index, a number means a specific index.

indexMat = nan(3,2); 

if ~isempty(regexp(tagGO,'{GO}', 'once'))
elseif ~isempty(regexp(tagGO,'{GO:s+\d}', 'once'))
  indices = regexp(tagGO,'{GO:s(\d+)}','tokens');
  indexMat(1,1) = str2double(indices{1}{1});
elseif ~isempty(regexp(tagGO,'{GO:r+\d}', 'once'))
  indices = regexp(tagGO,'{GO:r(\d+)}','tokens');
  indexMat(2,1) = str2double(indices{1}{1});
elseif ~isempty(regexp(tagGO,'{GO:c+\d}', 'once'))
  indices = regexp(tagGO,'{GO:c(\d+)}','tokens');
  indexMat(3,1) = str2double(indices{1}{1});
elseif ~isempty(regexp(tagGO,'{GO:s+\d,r+\d}', 'once'))
  indices = regexp(tagGO,'{GO:s(\d+),r(\d+)','tokens');
  indexMat(1,1) = str2double(indices{1}{1});
  indexMat(2,1) = str2double(indices{1}{2});
elseif ~isempty(regexp(tagGO,'{GO:s+\d,c+\d}', 'once'))
  indices = regexp(tagGO,'{GO:s(\d+),c(\d+)}','tokens');
  indexMat(1,1) = str2double(indices{1}{1});
  indexMat(3,1) = str2double(indices{1}{2});
elseif ~isempty(regexp(tagGO,'{GO:r+\d,c+\d}', 'once'))
  indices = regexp(tagGO,'{GO:r(\d+),c(\d+)}','tokens');
  indexMat(2,1) = str2double(indices{1}{1});
  indexMat(3,1) = str2double(indices{1}{2});
elseif ~isempty(regexp(tagGO,'{GO:s+\d,r+\d,c+\d}', 'once'))
  indices = regexp(tagGO,'{GO:s(\d+),r(\d+),c(\d+)}','tokens');
  indexMat(1,1) = str2double(indices{1}{1});
  indexMat(2,1) = str2double(indices{1}{2});
  indexMat(3,1) = str2double(indices{1}{3});
end

if ~isempty(regexp(trialCat,'^stopTrial_', 'once'))
  if ~isempty(regexp(tagSTOP,'{STOP}', 'once'))
  elseif ~isempty(regexp(tagSTOP,'{STOP:s+\d}', 'once'))
    indices = regexp(tagSTOP,'{STOP:s(\d+)}','tokens');
    indexMat(1,2) = str2double(indices{1}{1});
  elseif ~isempty(regexp(tagSTOP,'{STOP:r+\d}', 'once'))
    indices = regexp(tagSTOP,'{STOP:r(\d+)}','tokens');
    indexMat(2,2) = str2double(indices{1}{1});
  elseif ~isempty(regexp(tagSTOP,'{STOP:c+\d}', 'once'))
    indices = regexp(tagSTOP,'{STOP:c(\d+)}','tokens');
    indexMat(3,2) = str2double(indices{1}{1});
  elseif ~isempty(regexp(tagSTOP,'{STOP:s+\d,r+\d}', 'once'))
    indices = regexp(tagSTOP,'{STOP:s(\d+),r(\d+)','tokens');
    indexMat(1,2) = str2double(indices{1}{1});
    indexMat(2,2) = str2double(indices{1}{2});
  elseif ~isempty(regexp(tagSTOP,'{STOP:s+\d,c+\d}', 'once'))
    indices = regexp(tagSTOP,'{STOP:s(\d+),c(\d+)}','tokens');
    indexMat(1,2) = str2double(indices{1}{1});
    indexMat(3,2) = str2double(indices{1}{2});
  elseif ~isempty(regexp(tagSTOP,'{STOP:r+\d,c+\d}', 'once'))
    indices = regexp(tagSTOP,'{STOP:r(\d+),c(\d+)}','tokens');
    indexMat(2,2) = str2double(indices{1}{1});
    indexMat(3,2) = str2double(indices{1}{2});
  elseif ~isempty(regexp(tagSTOP,'{STOP:s+\d,r+\d,c+\d}', 'once'))
    indices = regexp(tagSTOP,'{STOP:s(\d+),r(\d+),c(\d+)}','tokens');
    indexMat(1,2) = str2double(indices{1}{1});
    indexMat(2,2) = str2double(indices{1}{2});
    indexMat(3,2) = str2double(indices{1}{3});
  end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. CONVERT X TO INDIVIDUAL PARAMETERS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

z0 = get_value_per_xcat(SAM,X,indexMat,iZ0);
zc = get_value_per_xcat(SAM,X,indexMat,iZc);
v  = get_value_per_xcat(SAM,X,indexMat,iV);
ve = get_value_per_xcat(SAM,X,indexMat,iVe);
t0 = get_value_per_xcat(SAM,X,indexMat,iT0);
se = get_value_per_xcat(SAM,X,indexMat,iSe);
si = get_value_per_xcat(SAM,X,indexMat,iSi);
k  = get_value_per_xcat(SAM,X,indexMat,iK);
w  = get_value_per_xcat(SAM,X,indexMat,iW);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. ENCODE CONNECTIVITY MATRICES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Consider adding an additional parameter class to distinguish lateral inhibition within and between accumulator classes

% Endogenous connectivity
endoConnSelf          = endoConn.self * diag(blkdiag(trueN{:}) * k(:));
endoConnNonSelfSame   = endoConn.nonSelfSame * diag(blkdiag(trueN{:}) * w(:));
endoConnNonSelfOther  = endoConn.nonSelfOther * diag(blkdiag(trueN{:}) * w(:));
endoConn              = endoConnSelf + endoConnNonSelfSame + endoConnNonSelfOther;

% Extrinsic and intrinsic modulation 
extrMod = zeros(sum(N),sum(N),sum(M));
intrMod = zeros(sum(N),sum(N),sum(N));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. ENCODE STARTING POINT MATRIX
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

Z0 = blkdiag(trueN{:}) * z0(:);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 5. ENCODE THRESHOLD MATRIX
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

ZC = blkdiag(trueN{:}) * zc(:);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 6. ACCUMULATION RATES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

V = blkdiag(iTarget{:}) * v + blkdiag(iNonTarget{:}) * ve;

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 7. EXTRINSIC AND INTRINSIC NOISE
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

SE = diag(blkdiag(trueM{:}) * se(:));
SI = diag(blkdiag(trueN{:}) * si(:));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 8. SPECIFY ONSETS AND DURATIONS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

T0 = blkdiag(trueM{:}) * t0(:);

% THIS NEEDS TO BE IMPLEMENTED

% thisAccumDur = stimDur{iCnd,iTrType}(:)';
%     
%     % 4.2.1. Adjust duration of the STOP process, if needed
%     % ---------------------------------------------------------------------
%     if iTrType > 1
%       switch durationSTOP
%         case 'trial'
%           % STOP accumulation process lasts the entire trial
%           thisAccumDur(iSTOP) = timeWindow(2) - thisAccumOns(iSTOP);
%       end
%     end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% #. NESTED FUNCTIONS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

function xval = get_value_per_xcat(SAM,X,iMat,iCol)
    
    switch lower(SAM.sim.scope)
      case 'go'
        xval = SAM.model.XCat.valExcluded(iCol)*ones(1,1);
      case 'all'
        xval = SAM.model.XCat.valExcluded(iCol)*ones(2,1);
    end
    
    % Vector of parameter category values in X
    valuesGO = X(SAM.model.variants.toFit.XSpec.i.iCatClass{1,iCol});
    
    % Signature
    signatureGO = SAM.model.variants.toFit.features(:,iCol,1);
    
    if ~isempty(valuesGO) % Excluded value is used when valuesGO is empty
      if sum(signatureGO) > 1  
      elseif sum(signatureGO) == 1
        xval(1) = valuesGO(iMat(signatureGO,1));
      elseif sum(signatureGO) == 0
        xval(1) = valuesGO;
      end
    end
    
    switch lower(SAM.sim.scope)
      case 'all'
        
        % Vector of parameter category values in X
        valuesSTOP = X(SAM.model.variants.toFit.XSpec.i.iCatClass{2,iCol});

        % Signature
        signatureSTOP = SAM.model.variants.toFit.features(:,iCol,2);
        
        if ~isempty(valuesSTOP) % Excluded value is used when valuesSTOP is empty
          if sum(signatureSTOP) > 1  
          elseif sum(signatureSTOP) == 1
            xval(2) = valuesSTOP(iMat(signatureSTOP,1));
          elseif sum(signatureSTOP) == 0
            xval(2) = valuesSTOP;
          end
        end
    end    
  