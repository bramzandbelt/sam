function [rtQ,cumProbDefective,probMass,probMassDefective] = sam_bin_data(rt,prop,cumProb,minSize)
% SAM_BIN_DATA Groups RT into bins
%  
% DESCRIPTION 
% RT bin edges are defined based on cumulative probabilities
% 
% SYNTAX
% rtQ,cumProbDefect,probMass,probMassDefective] = SAM_BIN_DATA(rt,prop,cumProb,minSize)
% 
% rt        - reaction times (Nx1 double)
% prop      - proportion of trials in this category (1x1 double), with
%             category being either go trials or stop trials, e.g.
%             * correct (choice) go trials in the category of go trials 
%             * correct (choice) signal-respond trials in the category of
%             stop trials
% cumProb   - cumulative probabilities for which to compute RT quantiles (1xP double)
% minSize   - minimum number of trials for binning (1x1 or 1x2 double)
%             * if scalar, RT data with fewer than minSize trials are 
%             * if 1x2 double, RT data with fewer trials than 
%               + min(minSize) are grouped into one bin
%               + max(minSize) are grouped into two bins (median-split)
%
% EXAMPLES
% rt        = 400 + 100 * randn(500,1) + exprnd(150,500,1);
% prop      = 0.95;
% cumProb   = .1:.2:.9;
% minSize   = 40;
% [rtQ,cumProbDefect,probMass,probMassDefective] = ...
% SAM_BIN_DATA(rt,prop,cumProb,minSize);
%
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Wed 28 Aug 2013 14:40:48 CDT by bram 
% $Modified: Wed 28 Aug 2013 15:28:13 CDT by bram
 
% CONTENTS 
 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS AND SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Remove NaNs from RT vector, if any
% =========================================================================

if ~isempty(find(isnan(rt), 1))
    rt = rt(~isnan(rt));
end

% If there are too few trials, adjust the cumulative probabilities
% =========================================================================

if numel(minSize) == 1
    if numel(rt) < minSize
      % If fewer trials than minSize, group into one bin
      cumProb = [0 1];
    end
elseif numel(minSize) == 2
    if numel(rt) < minSize
      % If fewer trials than minimum of minSize, group into one bin
      cumProb = [0 1];
    elseif numel(rt) < minSize
      % If fewer trials than maximum of minSize, group into two bins
      cumProb = [0 0.5 1];
    end
else
    error('minSize should be a 1x1 or 1x2 double.');
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 2. COMPUTE QUANTILES, PROBABILITIES, AND PROBABILITY MASSES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% RT quantiles
% =========================================================================
if isempty(rt)
  rtQ         = quantile(1e4,cumProb);
else
  rtQ         = quantile(rt,cumProb);
end

% This ensures that the slowest RT falls within the bin, instead of falling
% in a separate bin
if numel(rt) < minSize
  rtQ(2)    = rtQ(2) + 1;
end

% Defective cumulative probabilities
% =========================================================================
cumProbDefective     = cumProb.*prop;

% Probability masses and defective probability masses
% =========================================================================
if isempty(rt)
  histCount   = histc(1e4,[-Inf,rtQ,Inf]);
else
  histCount   = histc(rt,[-Inf,rtQ,Inf]);
end
histCount             = histCount(1:end-1);
probMass              = histCount./sum(histCount);
probMass              = probMass(:);
probMassDefective     = prop.*probMass;