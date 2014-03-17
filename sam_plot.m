function sam_plot(SAM,prd);

obs = SAM.optim.obs;

nTrialCat = size(obs,1);

% Set up panel
figure('units','normalized','outerposition',[0 0 1 1]);
p = panel();
p.pack(3,6);

for iTrialCat = 1:nTrialCat

  nPrdTotal               = prd.nTotal(iTrialCat);
  nPrdCorr                = prd.nCorr(iTrialCat);
  nPrdError               = prd.nError(iTrialCat);

  rtPrdCorr               = nan(nPrdTotal,1);
  rtPrdCorr(1:nPrdCorr)   = prd.rtCorr{iTrialCat};
  rtPrdError              = nan(nPrdTotal,1);
  rtPrdError(1:nPrdError) = prd.rtError{iTrialCat};
  
  nObsCorr                = obs.nCorr(iTrialCat);
  nObsError               = obs.nError(iTrialCat);
  
  rtQObsCorr              = obs.rtQCorr{iTrialCat};
  rtQObsError             = obs.rtQError{iTrialCat};
  pDefectiveObsCorr       = obs.pDefectiveCorr{iTrialCat};
  pDefectiveObsError      = obs.pDefectiveError{iTrialCat};
  
  % Plot
  [iColumn,iRow] = ind2sub([6,3],iTrialCat);
  p(iRow,iColumn).select();
  p(iRow,iColumn).hold('on');
  
  % Predictions as lines
  plot(rtPrdCorr,cmtb_edf(rtPrdCorr,rtPrdCorr),'Color','k','LineStyle','-');
  plot(rtPrdError,cmtb_edf(rtPrdError,rtPrdError),'Color','k','LineStyle','--');
  
  % Observations as circles
  plot(rtQObsCorr,pDefectiveObsCorr,'ko');
  plot(rtQObsError,pDefectiveObsError,'kd');
  
  % Set title
  title(obs.trialCat{iTrialCat});
  set(gca,'XLim',[0 2000],'YLim',[0 1]);
  
  % Legend
  legend(sprintf('Corr(N_O=%d,N_P=%d)',nObsCorr,nPrdCorr),sprintf('Error(N_O=%d,N_P=%d)',nObsError,nPrdError));
  
end