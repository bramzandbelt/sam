function [rt,resp,z] = sam_sim_trial_cffi_ibi_nomodbd(u,A,~,C,~,SI, ...
                                                         Z0,ZC,ZLB,dt, ...
                                                         tau,T, ...
                                                         terminate,blockInput,~)
% Simulate trials: C as feed-forward inhibition, I as blocked input, no extr. and intr. modulation
% 
% DESCRIPTION 
% SAM trial simulation function, modeling choice as feed-forward 
% inhibition, inhibition as blocking the input, and excluding extrinisic 
% (B) or intrinisic (D) modulation of connectivity.
%
% SYNTAX 
% Let there be M inputs, N units, P time points, then
% u           - inputs to the accumulators (MxP double)
% A           - endogenous connectivity matrix (NxN double)
% B           - extrinsic modulation matrix (NxNxM double)
% C           - exogenous connectivity matrix (NxM double)
% D           - intrinsic modulation matrix (NxNxN double)
% SI          - intrinsic noise strength (MxM double)
% Z0          - starting value of activation (Nx1 double)
% ZC          - threshold on activation (Nx1 double)
% ZLB         - lower bound on activation (Nx1 double)
% dt          - time step (1x1 double)
% tau         - time scale (1x1 double)
% T           - time points (1xP double)
% terminate   - matrix indicating which units can terminate accumulation of
%               activation when they reach threshold (Nx1 logical)
% blockInput  - matrix indicating which units block which inputs when they
%               reach threshold (Nx1 logical)
% latInhib    - matrix indicating which elements in A remain 0 as long as
%               unit n (indexed by the columns of A) has not reached 
%               threshold (indexed by resp)
%
% rt          - response times (Nx1 double)
% resp        - responses, inid (Nx1 logical)
% z           - activation (NxP double)
%
% [rt,resp,z] = SAM_SIM_TRIAL_CFFI_IBI_NOMODBD(u,A,~,C,~,SI,Z0,ZC, ...
%                                                 ZLB,dt,tau,T, ...
%                                                 terminate,~,~);
%
% EXAMPLES 
%
% ......................................................................... 
% Bram Zandbelt, bramzandbelt@gmail.com 
% $Created : Wed 24 Jul 2013 12:14:48 CDT by bram 
% $Modified: Wed 18 Sep 2013 09:20:56 CDT by bram

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% 1. PROCESS INPUTS & SPECIFY VARIABLES
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% 1.1. Dynamic variables
% =========================================================================
n       = size(A,1);  % Number of units
% m       = size(C,1);  % Number of inputs to units
p       = size(u,2);  % Number of time points
t       = 1;          % Time index

% 1.2. Pre-allocate arrays for logging data
% =========================================================================
rt      = inf(n,1);       % Response time
resp    = false(n,1);     % Response (i.e. whether a unit has reached zc)
z       = nan(n,p);       % Activation

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% #. STOCHASTIC ACCUMULATION PROCESS
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

% Sample starting point from uniform distribution on interval [0,Z0]
z(:,1)  = 0 + (Z0-0).*rand(n,1);
% z(:,1)  = Z0;  

while t < p - 1
  
%   % Endogenous connectivity at time t (note that A is a function of t
%   % because lateral inhibition kicks in once a unit has reached its
%   % threshold)
%   % -----------------------------------------------------------------------
%   At = A;
  
%   % Extrinsic modulation at time t
%   % -----------------------------------------------------------------------
%   Bt          = zeros(m,m);
%   for i = 1:m
%     Bt        = Bt + u(i,t)*B(:,:,i);
%   end

%   % Intrinsic modulation at time t
%   % -----------------------------------------------------------------------
%   Dt          = zeros(n,n);
%   for j = 1:n
%     Dt        = Dt + z(j,t)*D(:,:,j);
%   end

  % Inhibition mechanism 1: block input(s), if any
  % -----------------------------------------------------------------------
  u(any(blockInput(:,resp),2),t) = 0;
  
%   % Inhibition mechanism 2: lateral inhibition
%   % -----------------------------------------------------------------------
%   At(latInhib(:,~resp)) = 0;
  
%   % Change in activation from time t to t + 1
%   % -----------------------------------------------------------------------
%   dzdt        = (At + Bt + Dt)  * z(:,t)      * dt/tau + ...  % 
%                 C               * u(:,t)      * dt/tau + ...  % Inputs
%                 SI             * randn(n,1)  * sqrt(dt/tau); % Noise (in)
              
  dzdt        = C   * u(:,t)      * dt/tau + ...   % Inputs
                SI  * randn(n,1)  * sqrt(dt/tau);  % Noise (in)
              
  % Log new activation level
  % -----------------------------------------------------------------------
  z(:,t+1)    = z(:,t) + dzdt;

  % Rectify activation if below zLB
  % -----------------------------------------------------------------------
  z(z(:,t+1) < ZLB,t+1) = ZLB(z(:,t+1) < ZLB);

  % Identify units that crossed threshold
  % -----------------------------------------------------------------------
  resp(z(:,t+1) > ZC) = true;
  
  % Determine time of crossing threshold
  % -----------------------------------------------------------------------
  rt(resp & isinf(rt)) = T(t + 1);
  
  % Break accumulation if termination criterion has been met
  % -----------------------------------------------------------------------
  if any(terminate(resp))
    break
  end
  
  % Update time
  % -----------------------------------------------------------------------
  t = t + 1;
  
end