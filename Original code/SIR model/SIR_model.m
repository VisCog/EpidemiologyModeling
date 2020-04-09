% SIR_model.m
%
% Implements the standard 'SIR' compartmental model, as described in:
% https://en.wikipedia.org/wiki/Compartmental_models_in_epidemiology
%
% April, 2020, G.M. Boynton
%
%
% Notes:
%
% The SIR model is a system of differential equations, with time-varying
% variables, S (susceptible), I (infected), and R (recovered).  N is the
% total population.
%
% dS/dt = -beta*I/N
% dI/dt = beta*I*S/N - gamma*I
% dR/dt = gamma*I
%
% Built into this is the fact that:
%
% N = S+I+R, and dS/dt + dI/dt + dR/dt = 0
%
% Note that when S ~ N, like at t=0 when everyone is susceptible:
%
% dI/dt = (beta-gamma)*I, which is exponential growth: y = exp((beta-gamma)*t).

clear all

% Model parameters:
gamma =.4;% .9;              % recovery rate
beta = .65; %1.1;             % infection rate 
delta = .02;          % proportion 'Recovered' that are dead;

dt = 1/10;              % time step constant for simulation
nDays=  60;
t=1:dt:nDays;

% zero out vectors to be filled in over time
S = zeros(size(t));
I = zeros(size(t));
R = zeros(size(t));

% Initial conditions:
N = 100;                 % total population
S(1) = N;                % starting susceptible 'stock'
I(1) = 1;                % starting infected 'stock' (one person)
R(1) = N-S(1)-I(1);      % starting resistant 'stock' S+I+R = N

% Simple implementation using Euler's method
for i=1:(length(t)-1)
    % rates of change of S, I and R
    dS = -beta*I(i)*S(i)/N;
    dI =  beta*I(i)*S(i)/N - gamma*I(i);
    dR = gamma*I(i);
    
    % add rates of change to S, I and R
    S(i+1) = S(i)+dS*dt;
    I(i+1) = I(i)+dI*dt;
    R(i+1) = R(i)+dR*dt;
end

%% Plot the results
figure(1)
clf
hold on
plot(t,S,'b-');
plot(t,I,'g-');
plot(t,R,'r-');
legend({'Susceptible','Infected','Recovered'});
xlabel('Time (days)');


title(sprintf('$\\beta = %g, \\gamma = %g $',beta,gamma),'Interpreter','latex');
set(gca,'YLim',[-1,N+1]);

%% Plot of infected curve on log axis
figure(2)
clf
hold on

plot(t,log(I),'g-')

% infections follow exp(beta-gamma) kn the beginning of the oubreak
plot(t,log(exp((t-1)*(beta-gamma))),'b--');
xlabel('Time (days)');
set(gca,'YTick',log(10.^[0:.5:10]));
logy2raw(exp(1),0)
ylim = [0,max(log(I))*1.5];
set(gca,'YLim',ylim);
grid

STmax = gamma*N/beta;    % number susceptible when infection is maximal

tmp = find(S>STmax);
tmax = t(tmp(end));
plot(tmax*[1,1],ylim,'k:','LineWidth',2);
dead = round((R(end)+I(end))*delta);
title(sprintf('Maximum infected: %4.0f after %d days. %d dead (%2.1f%%)',I(tmp(end)),round(tmax),dead,100*dead/N));
ylabel('Infected')
