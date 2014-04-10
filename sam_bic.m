function bic = sam_bic(pMObs,pMPrd,fObs,nFree)
% SAM_BIC <Synopsis of what this function does> 
%  
% DESCRIPTION 
% <Describe more extensively what this function does> 
%  
% SYNTAX 
% SAM_BIC; 
%  
% pMObs       observed probability mass
% pMPrd       predicted probability mass
% fObs        observed frequency
% nFree       number of free parameters
%
% REFERENCES 
% Leite, F. P., & Ratcliff, R. (2010). Modeling reaction time and accuracy of multiple-alternative decisions. 
% Attention, Perception, & Psychophysics, 72(1), 246?273.
%
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Thu 10 Apr 2014 14:29:49 CDT by bram 
% $Modified: Thu 10 Apr 2014 14:29:49 CDT by bram 
bic = -2 * sum((pMObs.*fObs) .* log(pMPrd)) + nFree * log(sum(fObs));

