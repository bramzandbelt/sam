iCnd = 1;
iGOT = 3;
iSTOP = 7;
N = [6 1];

% Figure
hFig = set_figure({1000,750,'pixels'},{'USLetter','landscape'},{'Helvetica',12});

figName = sprintf('ChoiceMech: %s, InhibitionMech: %s', ...
                  SAM.des.choiceMech.type, ...
                  SAM.des.inhibMech.type);
set(gcf,'MenuBar','none',...
        'Name',figName, ...
        'NumberTitle','off', ...
        'Toolbar','none');


p = panel;
p.margin = [15 15 5 5];

p.pack(4,2);


% EdgeAlpha level:
edgeAlpha = 0.05;

% Colors
colGOT  = [0 0.5 0];
colGONT = [0.5 0.5 0];
colGONTE = [0.5 0.5 0];
colSTOP = [1 0 0];

% Settings of axes
xStimLim = [250 2250];
xDataLim = [0 2000];

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GO TRIALS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iGoTrType = 1;

% Timing diagrams
% =========================================================================
p(1,1).margin = [15 0 5 2];
p(1,1).pack('v',[1/4,3/4]);

% Stimuli
% -------------------------------------------------------------------------

% Split into two vertical panels
p(1,1,1).pack('v',2);

% Get data
X = repmat(prd.tDiagram{iCnd,iGoTrType}.stim.go.X,1,2);
Y = prd.tDiagram{iCnd,iGoTrType}.stim.go.Y([iGOT,iSTOP],:)';

label = {'go','stop'};

% Plot data
for i = 1:2
  p(1,1,1,i).select();
  stairs(X(:,i),Y(:,i),'k-');
  
  % Adjust axes
  set(gca,'XLim',xStimLim, ...
          'YLim',[-0.1,1]);
  text(diff(xStimLim)*-0.02 + xStimLim(1),0,label{i}, ...
       'HorizontalAlignment','right', ...
       'VerticalAlignment','middle')
     axis off
end

% Model inputs
% -------------------------------------------------------------------------

% Split into four vertical panels
p(1,1,2).pack('v',sum(N));

% Get data
X = repmat(prd.tDiagram{iCnd,iGoTrType}.modelinput.go.X,1,sum(N));
Y = prd.tDiagram{iCnd,iGoTrType}.modelinput.go.Y';

label = {'GO1','GO2','GO3','GO4','GO5','GO6','STOP'};

% Plot data
for i = 1:sum(N)
  p(1,1,2,i).select();
  stairs(X(:,i),Y(:,i),'k-');
  
  % Adjust axes
  set(gca,'XLim',xStimLim, ...
          'YLim',[-0.1,max(Y(:))]);
  text(diff(xStimLim)*-0.02 + xStimLim(1),0,label{i}, ...
       'HorizontalAlignment','right', ...
       'VerticalAlignment','middle')
     axis off
end

% Response times
% =========================================================================

% Select panel
p(2,1).select();
p(2,1).hold('on');

% Get RT data
rtGoCorr = sort(prd.rtGoCorr{iCnd});
rtGoComm = sort(prd.rtGoComm{iCnd});

% Cumulative probabilities
FGoCorr = mtb_edf(rtGoCorr(:),rtGoCorr(:));
FGoComm = mtb_edf(rtGoComm(:),rtGoComm(:));

% Plot data
plot(rtGoCorr,FGoCorr,'Color',colGOT,'LineWidth',3);
plot(rtGoComm,FGoComm,'Color',colGONTE,'LineWidth',3);

% Adjust axes
set(gca,'XLim',xDataLim, ...
         'YTick',[0 1]);
ylabel('Cumulative probability');
title('RTs and probabilities on no-signal trials');
axes('Position',[0.08 0.6 0.1 0.1])

if ~any([prd.pGoCorr(iCnd),prd.pGoComm(iCnd),prd.pGoOmit(iCnd)] == 0)
  hPie = pie(gca,[prd.pGoCorr(iCnd),prd.pGoComm(iCnd),prd.pGoOmit(iCnd)],{'Corr','Comm','Omit'});
  colormap([colGOT;colGONTE;[0.8 0.8 0.8]]);
elseif prd.pGoComm(iCnd) == 0
  hPie = pie(gca,[prd.pGoCorr(iCnd)],{'Corr'});
  colormap([colGOT]);
elseif prd.pGoOmit(iCnd) == 0
  hPie = pie(gca,[prd.pGoCorr(iCnd),prd.pGoComm(iCnd)],{'Corr','Comm'});
  colormap([colGOT;colGONTE]);
end

clear rtGoCorr rtGoComm FGoCorr FGoComm hPie

% Dynamics Go correct trial
% =========================================================================

if prd.pGoCorr(iCnd) > 0

  % Select panel
  p(3,1).select();
  p(3,1).hold('on');

  % Get individual trial dynamics
  sXGOT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GOT.sX;
  sYGOT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GOT.sY;
  sXGONT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GONT.sX;
  sYGONT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GONT.sY;

  % Get quantile averaged dynamics
  qXGOT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GOT.qX;
  qYGOT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GOT.qY;
  qXGONT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GONT.qX;
  qYGONT = prd.dyn{iCnd,iGoTrType}.GoCorr.goStim.GONT.qY;

  % Plot data
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colGOT,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXGOT,sYGOT,'Uni',0);
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colGONT,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXGONT,sYGONT,'Uni',0);

  plot(qXGOT,qYGOT,'Color',colGOT,'LineWidth',3);
  plot(qXGONT,qYGONT,'Color',colGONT,'LineWidth',3);

  line([xDataLim(1),xDataLim(2)], ...
       [modelMat.ZC{iCnd}(iGOT),modelMat.ZC{iCnd}(iGOT)], 'Color','k','LineWidth',3);

  % Adjust axes
  set(gca,'XLim',xDataLim);
  ylabel('Activation (a.u.)');
  title('Dynamics on correct no-signal trials')

  clear sXGOT sYGOT sXGONT sYGONT qXGOT qYGOT qXGONT qYGONT
  
end

% Dynamics Go commission error trial
% =========================================================================

if prd.pGoComm(iCnd) > 0

  % Select panel
  p(4,1).select();
  p(4,1).hold('on');

  % Get individual trial dynamics
  sXGOT = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GOT.sX;
  sYGOT = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GOT.sY;
  sXGONTE = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GONTE.sX;
  sYGONTE = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GONTE.sY;

  % Get quantile averaged dynamics
  qXGOT = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GOT.qX;
  qYGOT = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GOT.qY;
  qXGONTE = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GONTE.qX;
  qYGONTE = prd.dyn{iCnd,iGoTrType}.GoComm.goStim.GONTE.qY;

  % Plot data
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colGOT,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXGOT,sYGOT,'Uni',0);
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colGONTE,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXGONTE,sYGONTE,'Uni',0);

  plot(qXGOT,qYGOT,'Color',colGOT,'LineWidth',3);
  plot(qXGONTE,qYGONTE,'Color',colGONTE,'LineWidth',3);

  line([xDataLim(1),xDataLim(2)], ...
       [modelMat.ZC{iCnd}(iGOT),modelMat.ZC{iCnd}(iGOT)], 'Color','k','LineWidth',3);

  % Adjust axes
  set(gca,'XLim',xDataLim);
  xlabel('Time from go-signal (ms');
  ylabel('Activation (a.u.)');
  title('Dynamics on choice error no-signal trials');

  clear sXGOT sYGOT sXGONTE sYGONTE qXGOT qYGOT qXGONTE qYGONTE
  
end

% =========================================================================
% STOP TRIALS
% =========================================================================

iStopTrType = 5;

% Timing diagrams
% =========================================================================
p(1,2).margin = [15 0 5 2];
p(1,2).pack('v',[1/4,3/4]);

% Stimuli
% -------------------------------------------------------------------------

% Split into two vertical panels
p(1,2,1).pack('v',2);

% Get data
X = repmat(prd.tDiagram{iCnd,iStopTrType}.stim.stop.X,1,2);
Y = prd.tDiagram{iCnd,iStopTrType}.stim.stop.Y([iGOT,iSTOP],:)';

label = {'go','stop'};

% Plot data
for i = 1:2
  p(1,2,1,i).select();
  stairs(X(:,i),Y(:,i),'k-');
  
  % Adjust axes
  set(gca,'XLim',xStimLim, ...
          'YLim',[-0.1,1]);
  text(diff(xStimLim)*-0.02 + xStimLim(1),0,label{i}, ...
       'HorizontalAlignment','right', ...
       'VerticalAlignment','middle')
     axis off
end

% Model inputs
% -------------------------------------------------------------------------

% Split into four vertical panels
p(1,2,2).pack('v',sum(N));

% Get data
X = repmat(prd.tDiagram{iCnd,iStopTrType}.modelinput.stop.X,1,sum(N));
Y = prd.tDiagram{iCnd,iStopTrType}.modelinput.stop.Y';

label = {'GO1','GO2','GO3','GO4','GO5','GO6','STOP'};

% Plot data
for i = 1:sum(N)
  p(1,2,2,i).select();
  stairs(X(:,i),Y(:,i),'k-');
  
  % Adjust axes
  set(gca,'XLim',xStimLim, ...
          'YLim',[-0.1*max(Y(:)),max(Y(:))]);
  text(diff(xStimLim)*-0.02 + xStimLim(1),0,label{i}, ...
       'HorizontalAlignment','right', ...
       'VerticalAlignment','middle')
     axis off
end

% Response times
% =========================================================================

% Split into two vertical panels
p(2,2).pack('v',2);

p(2,2,1).select();
p(2,2,1).hold('on');

% Get data
rtGo = sort([prd.rtGoCorr{iCnd},prd.rtGoComm{iCnd}]);
rtStopFailure = sort(prd.rtStopFailure{iCnd,iStopTrType-1});
rtStopSuccess = sort(prd.rtStopSuccess{iCnd,iStopTrType-1});

% Cumulative probabilities
FGo = mtb_edf(rtGo(:),rtGo(:));
FStopFailure = mtb_edf(rtStopFailure(:),rtStopFailure(:));
FStopSuccess = mtb_edf(rtStopSuccess(:),rtStopSuccess(:));

% Plot data
plot(rtGo,FGo,'Color',colGOT,'LineWidth',3,'LineStyle','-');
plot(rtStopFailure,FStopFailure,'Color',colGOT,'LineWidth',3,'LineStyle','--');
plot(rtStopSuccess,FStopSuccess,'Color',colSTOP,'LineWidth',3,'LineStyle','--');

% Adjust axes
set(gca,'XLim',xDataLim, ...
        'YLim',[0 1], ...
        'YTick',[0 1]);
ylabel('Cum. prob.')
title('RTs on no-signal and signal-respond trials');

p(2,2,2).select();
p(2,2,2).hold('on');

% Get data
inhibFunc = prd.inhibFunc{iCnd};
ssd = cell2mat(cellfun(@(a) a(7), SAM.des.expt.stimOns(iCnd,2:end),'Uni',0));

% Plot data
plot(ssd,inhibFunc,'k.','LineWidth',3);
plot(ssd(iStopTrType-1),inhibFunc(iStopTrType-1),'r.');

% Adjust axes
set(gca,'XLim',xDataLim, ...
        'YLim',[0 1], ...
        'YTick',[0 1]);
ylabel('Cum. prob.')
title('Inhibition function');

clear rtGo rtStopFailure FGo FStopFailure

% Dynamics StopSuccess trial
% =========================================================================

if prd.pStopSuccess(iCnd,iStopTrType-1) > 0

  % Select panel
  p(3,2).select();
  p(3,2).hold('on');

  % Get individual trial dynamics
  sXSTOP = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.STOP.sX;
  sYSTOP = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.STOP.sY;
  sXGOT  = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.GOT.sX;
  sYGOT  = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.GOT.sY;

  % Get quantile averaged dynamics
  qXSTOP = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.STOP.qX;
  qYSTOP = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.STOP.qY;
  qXGOT  = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.GOT.qX;
  qYGOT  = prd.dyn{iCnd,iStopTrType}.StopSuccess.goStim.GOT.qY;

  % Plot data
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colGOT,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXGOT,sYGOT,'Uni',0);
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colSTOP,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXSTOP,sYSTOP,'Uni',0);

  plot(qXGOT,qYGOT,'Color',colGOT,'LineWidth',3);
  plot(qXSTOP,qYSTOP,'Color',colSTOP,'LineWidth',3);

  line([xDataLim(1),xDataLim(2)], ...
       [modelMat.ZC{iCnd}(iSTOP),modelMat.ZC{iCnd}(iSTOP)], 'Color','k','LineWidth',3);

  % Adjust axes
  set(gca,'XLim',xDataLim);
  ylabel('Activation (a.u.)');
  title('Dynamics on signal-inhibit trials');

  clear sXSTOP sYSTOP sXGOT sYGOT qXSTOP qYSTOP qXGOT qYGOT
  
end

% Dynamics StopFailure trial
% =========================================================================

if prd.pStopFailure(iCnd,iStopTrType-1)
  
  % Select panel
  p(4,2).select();
  p(4,2).hold('on');

  % Get individual trial dynamics
  sXSTOP = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.STOP.sX;
  sYSTOP = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.STOP.sY;
  sXGORESP  = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.GORESP.sX;
  sYGORESP  = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.GORESP.sY;

  % Get quantile averaged dynamics
  qXSTOP = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.STOP.qX;
  qYSTOP = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.STOP.qY;
  qXGORESP  = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.GORESP.qX;
  qYGORESP  = prd.dyn{iCnd,iStopTrType}.StopFailure.goStim.GORESP.qY;

  % Plot data
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colSTOP,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXSTOP,sYSTOP,'Uni',0);
  cellfun(@(a,b) patchline(a,b,'EdgeColor',colGOT,'LineWidth',1,'EdgeAlpha',edgeAlpha),sXGORESP,sYGORESP,'Uni',0);

  plot(qXSTOP,qYSTOP,'Color',colSTOP,'LineWidth',3);
  plot(qXGORESP,qYGORESP,'Color',colGOT,'LineWidth',3);

  line([xDataLim(1),xDataLim(2)], ...
       [modelMat.ZC{iCnd}(iGOT),modelMat.ZC{iCnd}(iGOT)], 'Color','k','LineWidth',3);

  % Adjust axes
  set(gca,'XLim',xDataLim);
  xlabel('Time from go-signal (ms');
  ylabel('Activation (a.u.)');
  title('Dynamics on signal-respond trials');

  clear sXSTOP sYSTOP sXGOT sYGOT qXSTOP qYSTOP qXGOT qYGOT
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure plotting matrices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hFig = set_figure({1800,750,'pixels'},{'USLetter','landscape'},{'Helvetica',12});

figName = sprintf('ChoiceMech: %s, InhibitionMech: %s', ...
                  SAM.des.choiceMech.type, ...
                  SAM.des.inhibMech.type);
set(gcf,'MenuBar','none',...
        'Name',figName, ...
        'NumberTitle','off', ...
        'Toolbar','none');

clear p;
p = panel;
p.margin = [5 5 2 2];
p.pack(1,10);

% Matrix A:
p(1,1).select();
sam_grid_image(double(modelMat.A));
pos = get(gca,'Position');
pos(4) = 0.8;
set(gca,'Position',pos)
title('Endogenous connectivity');

% Matrix C:
p(1,2).select();
sam_grid_image(double(modelMat.C));
pos = get(gca,'Position');
pos(4) = 0.8;
set(gca,'Position',pos)
title('Exogenous connectivity');

% Matrix Z0:
p(1,3).select();
sam_grid_image(double(modelMat.Z0));
pos = get(gca,'Position');
pos(4) = 0.8;
set(gca,'Position',pos)
title('Upper bound of starting activation');

% Matrices V
p(1,4).pack('h',2);
p(1,4,1).select();
sam_grid_image(double(modelMat.V{iCnd,iGoTrType}));
title('Rates on Go trials');

p(1,4,2).select();
sam_grid_image(double(modelMat.V{iCnd,iStopTrType}));
title('Rates on Stop trials');

% Matrices SI
p(1,5).pack('h',2);
p(1,5,1).select();
sam_grid_image(double(modelMat.SI{iCnd,iGoTrType}));
title('Intrinsic noise on Go trials');

p(1,5,2).select();
sam_grid_image(double(modelMat.SI{iCnd,iStopTrType}));
title('Intrinsic noise  on Stop trials');

% Matrix ZC
p(1,6).select();
sam_grid_image(double(modelMat.ZC{iCnd}));
title('Threshold');

% Matrix ZLB
p(1,7).select();
sam_grid_image(double(modelMat.ZLB));
title('Lower bound on activation');

% Termination matrix
p(1,8).select();
sam_grid_image(double(modelMat.terminate));
title('Termination matrix');

% Blocked-input matrix
p(1,9).select();
sam_grid_image(double(modelMat.blockInput));
title('Blocked-input matrix');

% Lateral inhibition matrix
p(1,10).select();
sam_grid_image(double(modelMat.latInhib));
title('Lateral inhibition matrix');