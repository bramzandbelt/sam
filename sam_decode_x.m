function [A,B,C,D,V,SE,SI,Z0,ZC,accumOns] = ...
          sam_decode_x(SAM,X,stimOns,stimDur,N,M,VCor,VIncor,S)
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

% Choice mechanism type
choiceMechType = SAM.des.choiceMech.type;

% Inhibition mechanism type
inhibMechType = SAM.des.inhibMech.type;

% Parameter that varies across task conditions
condParam = SAM.des.condParam;

% Scope of the simulation
simScope = SAM.sim.scope;

% Number of conditions
nCnd  = SAM.des.expt.nCnd;

% Indices of GO inputs, per condition
iGO   = SAM.des.iGO;



iZ0 = SAM.des.XCat.i.iZ0;
iZc = SAM.des.XCat.i.iZc;
iV  = SAM.des.XCat.i.iV;
iK  = SAM.des.XCat.i.iK;


% 1.2. Specify dynamic variables
% ========================================================================= 

trueN = arrayfun(@(x) true(x,1),N,'Uni',0);
trueM = arrayfun(@(x) true(x,1),M,'Uni',0);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. CONVERT X TO INDIVIDUAL PARAMETERS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 



switch simScope
  case 'go'
    switch choiceMechType
      case 'li'
        
        z0  = X(model.XSpec.i.iCat{iZ0});
        zc  = X(model.XSpec.i.iCat{iZc});
        v   = X(model.XSpec.i.iCat{iV});
        ve  = X(model.XSpec.i.iCat{iVe});
        t0  = X(model.XSpec.i.iCat{iT0});
        si  = X(model.XSpec.i.iCat{iSi});
        se  = X(model.XSpec.i.iCat{iSe});
        k   = X(model.XSpec.i.iCat{iK});
        w   = X(model.XSpec.i.iCat{iW});
        
        
        
      otherwise
    end
  case 'all'
    switch choiceMechType
      case 'li'
      otherwise
        switch inhibMechType
          case 'li'
          otherwise
        end
    end
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 3. ENCODE CONNECTIVITY MATRICES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Endogenous connectivity
endoConnSelf          = endoConn.self * diag(blkdiag(trueN{:}) * k(:));
endoConnNonSelfSame   = endoConn.nonSelfSame * diag(blkdiag(trueN{:}) * w(:));
endoConnNonSelfOther  = endoConn.nonSelfOther * diag(blkdiag(trueN{:}) * w(:));
endoConn              = endoConnSelf + endoConnNonSelfSame + endoConnNonSelfOther;

% Exogneous connectivity
exoConn               = exoConn.mat;

% Think of how to incorporate different set sizes, without having to vary
% exoConn across different cells



% switch choiceMechType
%   case 'race'
%     
%     % Connectivity to self (leakage)
%     boolAS = logical(eye(sum(N)));
%     AS = boolAS*diag(blkdiag(trueN{:})*k(:));
%     
%     AOs = zeros(sum(N),sum(N));
%     
%     % No feed-forward inhibition
%     wFFI = repmat({0},nCnd,1);
%     
%   case 'ffi'
%     
%     % Connectivity to self (leakage)
%     boolAS = logical(eye(sum(N)));
%     AS = boolAS*diag(blkdiag(trueN{:})*k(:));
%     
%     AOs = zeros(sum(N),sum(N));
%         
%     % Feed-forward inhibition: normalized ffi of go-signals to all non-target GO units
%     wFFI = cellfun(@(a) -1./(numel(a)-1),SAM.des.iGO(:),'Uni',0);
%         
%   case 'li'
%     
%     % Connectivity to self (leakage)
%     boolAS = logical(eye(sum(N)));
%     AS = boolAS*diag(blkdiag(trueN{:})*k(:));
%     
%     % Connectivity to other units of same class
%     boolAOs = blkdiag(trueN{:})*blkdiag(trueN{:})' - boolAS;
%     AOs = boolAOs*diag(blkdiag(trueN{:})*w(:));
%     
%     % No feed-forward inhibition
%     wFFI = repmat({0},nCnd,1);
%     
% end
% 
% switch lower(simScope)
%   case 'all'
%     switch lower(inhibMechType)
%       case 'li'
% 
%         % Lateral inhibition to other units of other class
%         boolAOo = ~blkdiag(trueN{:})*blkdiag(trueN{:})';
%         AOo = boolAOo*diag(blkdiag(trueN{:})*w(:));
% 
%       otherwise
% 
%         % No lateral inhibition between GO and STOP
%         AOo = zeros(sum(N),sum(N));
% 
%     end
%   otherwise
%     
%     % No lateral inhibition between GO and STOP
%     AOo = zeros(sum(N),sum(N));
% end
% 
% % Ednogenous connectivity matrix
% A = AS + AOs + AOo;
% 
% % Exogneous connectivity matrix
% % =========================================================================
% % The number of units differs across conditions. When the choice mechanism
% % is feed-forward inhibition, so does the feed-forward inhibition weight.
% 
% C = cell(nCnd,1);
% for iCnd = 1:nCnd
%   trueIGO = zeros(1,N(1));
%   trueIGO(iGO{iCnd}) = true;
%   CGo = wFFI{iCnd}*(trueIGO(:)*trueIGO(:)'-diag(trueIGO)) + diag(trueIGO);
%   
%   switch lower(simScope)
%   case 'go'
%     C{iCnd} = blkdiag(CGo);
%   case 'all'
%     CStop = 1;
%     C{iCnd} = blkdiag(CGo,CStop);
%   end
% end

% Extrinsic and intrinsic modulation
B = zeros(sum(N),sum(N),sum(M));
D = zeros(sum(N),sum(N),sum(N));

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 4. ENCODE STARTING POINT MATRIX
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

Z0 = blkdiag(trueN{:})*z0(:);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 5. ENCODE THRESHOLD MATRIX
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

ZC = cell(nCnd,1);
switch lower(condParam)
  case 'zc'
    
    switch lower(simScope)
      % #.#.#. Optimize go trials only
      % -------------------------------------------------------------------
      case 'go'
        zcc1 = zc(1);
        ZC{1,1} = blkdiag(trueN{:})*zcc1(:);
        zcc2 = zc(2);
        ZC{2,1} = blkdiag(trueN{:})*zcc2(:);
        zcc3 = zc(3);
        ZC{3,1} = blkdiag(trueN{:})*zcc3(:);
        
      % #.#.#. Optimize all trials
      % -------------------------------------------------------------------
      case 'all'
        zcc1 = zc([1,4]);
        ZC{1,1} = blkdiag(trueN{:})*zcc1(:);
        zcc2 = zc([2,4]);
        ZC{2,1} = blkdiag(trueN{:})*zcc2(:);
        zcc3 = zc([3,4]);
        ZC{3,1} = blkdiag(trueN{:})*zcc3(:);
    end
    
  otherwise
    ZC = cellfun(@(a) blkdiag(trueN{:})*zc(:),ZC,'Uni',0);
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 6. ACCUMULATION RATES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch condParam
  
  % #.#. Rate varies between conditions
  % =======================================================================
  case 'v' 
    
    switch lower(simScope)
      
      
      % #.#.#. Optimize go trials only
      % -------------------------------------------------------------------
      case 'go'
        vc1 = vcor(1); % rate target go-signal in condition 1
        vc2 = vcor(2); % rate target go-signal in condition 2
        vc3 = vcor(3); % rate target go-signal in condition 3
      
        vi1 = vincor(1); % rate non-target go-signal in condition 1
        vi2 = vincor(2); % rate non-target go-signal in condition 2
        vi3 = vincor(3); % rate non-target go-signal in condition 3
        
        
      % #.#.#. Optimize all trials
      % -------------------------------------------------------------------
      case 'all'
        vc1 = vcor([1,4]); % rate go-signal and stop-signal in condition 1
        vc2 = vcor([2,4]); % rate go-signal and stop-signal in condition 2
        vc3 = vcor([3,4]); % rate go-signal and stop-signal in condition 3
        
        vi1 = [vincor(1),0]; % rate non-target go-signal and stop-signal in condition 1
        vi2 = [vincor(2),0]; % rate non-target go-signal and stop-signal in condition 2
        vi3 = [vincor(3),0]; % rate non-target go-signal and stop-signal in condition 3
        
    end
    
    % Rates in condition 1
    V(1,:) = cellfun(@(a,b) a*vc1(:) + b*vi1(:),VCor(1,:),VIncor(1,:),'Uni',0);
    
    % Rates in condition 2
    V(2,:) = cellfun(@(a,b) a*vc2(:) + b*vi2(:),VCor(2,:),VIncor(2,:),'Uni',0);
    
    % Rates in condition 3
    V(3,:) = cellfun(@(a,b) a*vc3(:) + b*vi3(:),VCor(3,:),VIncor(3,:),'Uni',0);
  
  % #.#. Rate does not vary between conditions
  % =======================================================================
  otherwise
    
    switch lower(simScope)
      case 'go'
      case 'all'
        vincor = [vincor,0];
    end
    
    V = cellfun(@(a,b) a*vcor(:) + b*vincor(:),VCor,VIncor,'Uni',0);
    
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 7. EXTRINSIC AND INTRINSIC NOISE
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

switch lower(simScope)
  case 'go'
    SE = cellfun(@(a) a*se,S,'Uni',0);
    SI = cellfun(@(a) a*si,S,'Uni',0); 
  case 'all'
    SE = cellfun(@(a) a*[se se]',S,'Uni',0);
    SI = cellfun(@(a) a*[si si]',S,'Uni',0); 
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 8. SPECIFY ONSETS AND DURATIONS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Accumulation
% =========================================================================
switch condParam
  
  case 't0' % Non-decision time varies between conditions
    
    switch lower(simScope)
      case 'go'
        t0c1 = t0(1);
        t0c2 = t0(2);
        t0c3 = t0(3);
      case 'all'
        t0c1 = t0([1,4]);
        t0c2 = t0([2,4]);
        t0c3 = t0([3,4]);
    end
    
    % Condition 1
    accumOns(1,:) = cellfun(@(a) a + blkdiag(trueM{:})*t0c1(:),stimOns(1,:),'Uni',0);
    
    % Condition 2
    accumOns(2,:) = cellfun(@(a) a + blkdiag(trueM{:})*t0c2(:),stimOns(2,:),'Uni',0);
    
    % Condition 3
    accumOns(3,:) = cellfun(@(a) a + blkdiag(trueM{:})*t0c3(:),stimOns(3,:),'Uni',0);
        
  otherwise % Non-decision time does not vary between conditions
    
    accumOns = cellfun(@(a) a + blkdiag(trueM{:})*t0(:),stimOns,'Uni',0);
    
end