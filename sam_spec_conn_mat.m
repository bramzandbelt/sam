function mat = sam_spec_conn_mat(SAM,choiceMech,stopMech)
% SAM_SPEC_CONN_MAT <Synopsis of what this function does> 
%  
% DESCRIPTION 
% The function specifies endogenous and exogneous connectivity matrices and how these are influenced by threshold crossing
%  
% SYNTAX 
% SAM_SPEC_CONN_MAT(SAM,choiceMech,stopMech); 
% choiceMech      - char array, choice mechanism, values can be 
%                   'race'    * race 
%                   'ffi'     * feed-forward inhibition
%                   'li'      * lateral inhibition
% stopMech        - char array, stop mechanism, values can be 
%                   'race'    * race 
%                   'bi'      * blocking input
%                   'li'      * lateral inhibition
%
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Thu 10 Apr 2014 12:45:26 CDT by bram 
% $Modified: Thu 10 Apr 2014 12:45:26 CDT by bram 

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 1.1. Process inputs
% =========================================================================
nRsp                            = SAM.expt.nRsp;
nStm                            = SAM.expt.nStm;

% 1.2. Define dynamic variables
% =========================================================================
trueNRsp                        = arrayfun(@(x) true(x,1),nRsp,'Uni',0);
trueNStm                        = arrayfun(@(x) true(x,1),nStm,'Uni',0);
iK                              = SAM.model.XCat.i.iK;
XCatIncluded                    = SAM.model.XCat.included;

% 1.3. Define static variables
% =========================================================================
endoConn                        = struct('self',[], ...
                                         'nonSelfSame',[], ...
                                         'nonSelfOther',[]);
exoConn                         = struct('mat',[], ...
                                         'w',[]);
mat                             = struct('endoConn',endoConn, ...
                                         'exoConn',exoConn, ...
                                         'terminate',[], ...
                                         'interClassBlockInp',[], ...
                                         'interClassLatInhib',[]);

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. COMPUTE MATRICES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% 2.1. Endogenous connectivity
% =========================================================================

% 2.1.1. Self-connectivity
% -------------------------------------------------------------------------

% If leakage constant included, then there is self-connectivity
if XCatIncluded(iK)
  mat.endoConn.self             = logical(eye(sum(nRsp)));
else
  mat.endoConn.self             = logical(false(sum(nRsp)));
end



% 2.1.2. Connectivity to other units from the same class
% -------------------------------------------------------------------------

% Units of same class have lateral connections only in 'li' choice mechanism
switch lower(choiceMech)
  case {'race','ffi'}
    mat.endoConn.nonSelfSame    = logical(false(sum(nRsp)));
  case 'li'
    mat.endoConn.nonSelfSame    = blkdiag(trueNRsp{:})*blkdiag(trueNRsp{:})' - ...
                                  mat.endoConn.self;
end

% 2.1.3. Connectivity to other units from the other class
% -------------------------------------------------------------------------

switch lower(stopMech)
  case {'race','bi'}
    mat.endoConn.nonSelfOther   = logical(false(sum(nRsp)));
  case 'li'
    mat.endoConn.nonSelfOther   = ~blkdiag(trueNRsp{:})*blkdiag(trueNRsp{:})';
  otherwise
    % e.g. when only go trials are simulated
    mat.endoConn.nonSelfOther   = logical(false(sum(nRsp)));
end

% 2.2. Exogenous connectivity
% =========================================================================

% 2.2.1. Input
% -------------------------------------------------------------------------
% Each stimulus drives the unit with the corresponding index
mat.exoConn.mat                 = logical(eye(sum(nRsp)));

% 2.2.2. Weighting of input
% -------------------------------------------------------------------------
switch lower(choiceMech)
  case {'race','li'}
    mat.exoConn.w               = 'none';
  case 'ffi'
    mat.exoConn.w               = 'normalized';
end

% 2.3. Threshold crossing rules
% =========================================================================

% 2.3.1. Units that can terminate the trial when crossing threshold
% -------------------------------------------------------------------------

switch lower(choiceMech)
  case 'race'
    % Both GO and STOP units reaching threshold can terminate the trial
    mat.terminate               = logical(blkdiag(trueNRsp{:})*[true true]');
  case {'ffi','li'}
    % Only GO units reaching threshold can terminate the trial
    mat.terminate               = logical(blkdiag(trueNRsp{:})*[true false]');
end

% 2.3.2. Blocking input to accumulators of other class
% -------------------------------------------------------------------------

switch lower(stopMech)
  case {'race','li'}
    % No input is blocked
    mat.interClassBlockInp      = logical((blkdiag(trueNStm{:})*[false false]') * ...
                                            (blkdiag(trueNRsp{:})*[false false]')');
  case 'bi'
    % Input to GO is blocked when STOP reaches threshold, 
    % input to STOP is blocked when GO reaches threshold.
    mat.interClassBlockInp      = logical((blkdiag(trueNStm{:})*[true false]') * ...
                                            (blkdiag(trueNRsp{:})*[false true]')' ...
                                            + ...
                                            (blkdiag(trueNStm{:})*[false true]') * ...
                                            (blkdiag(trueNRsp{:})*[true false]')');
  otherwise
    % e.g. when only go trials are simulated
    mat.interClassBlockInp      = logical((blkdiag(trueNStm{:})*[false false]') * ...
                                            (blkdiag(trueNRsp{:})*[false false]')');
end

% 2.3.3. Lateral inhibition of accumulators of other class
% -------------------------------------------------------------------------                                          

switch lower(stopMech)
  case {'race','bi'}
    mat.interClassLatInhib      = logical(false(sum(nRsp)));
  case 'li'
    % STOP inhibits GO when STOP reaches threshold, 
    % GO inhibits STOP when GO reaches threshold.
    mat.interClassLatInhib      = logical((blkdiag(trueNRsp{:})*[true false]') *  ...
                                            (blkdiag(trueNRsp{:})*[false true]')' ...
                                            + ...                                      
                                            (blkdiag(trueNRsp{:})*[false true]') *  ...
                                            (blkdiag(trueNRsp{:})*[true false]')');
  otherwise
    % e.g. when only go trials are simulated
    mat.interClassLatInhib      = logical(false(sum(nRsp)));
end