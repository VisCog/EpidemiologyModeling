% Pandemic_simulation.m
%
% Simulation of pandemic ourbreak using moving dots.  Based on (stolen
% from) the Washington Post artdicle:
%
% https://www.washingtonpost.com/graphics/2020/world/corona-simulator/
%
% April 2020, G.M. Boynton
%%
% Set up dot motion pathways
%
% Dots (people) live in a world between in x and y dimensions defined by
% p.margin. Positions, velocities and accelerations are represented in the
% complex domain, where z = x+iy.
%
% Dots move in a physics-based environment where dots repel each other with
% a force that drops with the square of the distance from each other. The
% strength of this force is defined by p.kDot.
%
% Dots bounce off walls, defined by the binary image 'walls'
%
% Dot speed is set to attract to a value near 'dot.speed'.  The strength of
% this attration is set by 'p.kSpeed'.  This keeps the overall energy
% constant.

%%
clear all

% Dot Motion Parameters:

p.nDots =256;       % number of dots (people)
p.dur = 60;        % duration of simulation (days)
p.size = 30;        % dot size
p.speed = 2; %2        % desired dot speed
p.kDot =.5;         % constant for repelling dots from each other
p.kSpeed =.5;       % constant for keeping dots at desired speed (p.speed)
p.infectDist =  .45;% distance between dots for infecttion
p.infectDur = 5;    % average duration of infection (days).  Poisson distribution
p.infectProb = 1;   % probability of infection when within range for each time step
p.dead = .025;      % probability of dying after infection ends
p.margin = [11,11]; % size of world (+/- width,height)
p.dt = 1/30;        % time step size.  1/p.dt is steps per day
p.draw = 2;         % update animation every pth frame (allows for fast simulations)

%% Define walls
p.dx = .5;  % sampling of background 'walls' image (width of walls)

[wx,wy] = meshgrid( -p.margin(1):p.dx:(p.margin(1)-p.dx),-p.margin(2):p.dx:(p.margin(2)-p.dx));

% Zero out 'walls' image
walls = zeros(2*fliplr(p.margin)/p.dx);

% Outer boundary
walls(1,:) = 1;
walls(end,:) = 1;
walls(:,1) = 1;
walls(:,end) = 1;

% 'Plus' divides the world into quadrants
% walls(round(size(walls,1)/2),1:end) = 1;
% walls(1:end,round(size(walls,2)/2)) = 1;

% gaps in the 'plus'

% walls(10,2:(end-1)) = 0;
% walls(end-10,2:(end-1)) = 0;
% walls(2:(end-1),10) = 0;
% walls(2:(end-1),end-10) = 0;
% walls(11,2:(end-1)) = 0;
% walls(end-11,2:(end-1)) = 0;
% walls(2:(end-1),11) = 0;
% walls(2:(end-1),end-11) = 0;

%% set up 'dot' structure.
%
% Dots have one of four states:
%           1: susceptible to infection
%           2: infected
%           3: recovered alive
%           4: 'recovered', dead

% All dots but one start out susceptible. One is infected
dots.state = ones(p.nDots,1);  % susceptible
dots.state(1) = 2;             % infected

% time vector
t = p.dt:p.dt:p.dur;

% starting dot positions (random, uniform)
dots.pos = p.margin(1)*(rand(p.nDots,1)*2-1)*.95 + p.margin(2)*(sqrt(-1)*(rand(p.nDots,1)*2-1)*.95);
id = hitWalls(p,real(dots.pos),imag(dots.pos),walls);

% replace dots generated inside walls
while ~isempty(id)
    dots.pos(id) =  p.margin(1)*(rand(length(id),1)*2-1)*.95 + p.margin(2)*(sqrt(-1)*(rand(length(id),1)*2-1)*.95);
    id = hitWalls(p,real(dots.pos),imag(dots.pos),walls);
end

% starting dot directions (dots.v are complex valued)
ang = rand(p.nDots,1)*pi*2;  %random direction
dots.v = p.speed*exp(sqrt(-1)*ang);

% starting accelerations (set to zero)
dots.a = zeros(p.nDots,1);

% starting infection life.  The one infectded dot will stay infected for
% p.infectDur days.
dots.ti = zeros(p.nDots,1);
dots.ti(dots.state==2) = p.infectDur;

% Set up dot colors, based on their states
colList = {[0,0,1],[1,0,0],[0,1,0],.9*[1,1,1]};  % Four states: b r g k
dots.col = zeros(p.nDots,3);
for i=1:4
    id = dots.state==i;
    dots.col(id,:) = repmat(colList{i},sum(id),1);
end

% set up the Matlab figure window for animation
figure(1)
clf
hold on

image(wx(1,:),wy(:,1),walls+1);
colormap([1,1,1;.5,.5,.5]);
set(gcf,'Color','w');
% h is a handle to all dot positions and colors
h = scatter(real(dots.pos),imag(dots.pos),p.size,dots.col,'filled','MarkerEdgeColor','k');

axis equal
set(gca,'XLim',p.margin(1)*1.05*[-1,1]);
set(gca,'YLim',p.margin(2)*1.05*[-1,1]);
axis off
set(gca,'YDir','normal') % 'up' is positive


% Zero out statistics for plotting at the end
S = zeros(size(t));  % suscecptible
I = zeros(size(t));  % infected
R = zeros(size(t));  % recovered (alive)
D = zeros(size(t));  % 'recovered' (dead)

% run the time loop
tcount =0;
tic
% stop when time runs out, or no more infections
while tcount < length(t)  & sum(dots.state==2)
    tcount = tcount+1;
    % update velocity by adding acceleration
    dots.v = dots.v + dots.a*p.dt;
    
    % update dot position by adding velocity
    dots.pos(dots.state<4) = dots.pos(dots.state<4)+dots.v(dots.state<4)*p.dt;
    
    % update the dot positions in the figure by modifying handle, h
    if mod(tcount,p.draw)==0;
        set(h,'XData',real(dots.pos));
        set(h,'YData',imag(dots.pos));
        drawnow
    end
    
    % calculate the accelerations (changes in velocity)
    
    % dots repel eachother
    z = repmat(dots.pos,1,p.nDots) - repmat(conj(dots.pos)',p.nDots,1);   % pair-wise vector between dots
    a = p.kDot*abs(z).^-2.*exp(sqrt(-1)*angle(z)); % pair-wise force between dots
    a(isinf(a)) = 0; % dots don't affect themselves
    dots.a = sum(a,2); % sum forces for each dot across all other dots
    
    %  dots bounce off walls
    id = hitWalls(p,real(dots.pos),imag(dots.pos),walls);
    
    %wall on right
    for i=1:length(id)
        v = dots.v(id(i));
        % right wall
        if ~isempty(hitWalls(p,real(dots.pos(id(i))+real(dots.v(id(i)))*p.dt),imag(dots.pos(id(i))),walls))        
            v = v - 2*real(v);          
        end
        % left wall
        if ~isempty(hitWalls(p,real(dots.pos(id(i))-real(dots.v(id(i)))*p.dt),imag(dots.pos(id(i))),walls))
            v = v - 2*real(v);
        end
        % lower wall
        if ~isempty(hitWalls(p,real(dots.pos(id(i))),imag(dots.pos(id(i)))-imag(dots.v(id(i)))*p.dt,walls))
            v = v - 2*imag(v)*sqrt(-1);
        end
        % upper wall
        if ~isempty(hitWalls(p,real(dots.pos(id(i))),imag(dots.pos(id(i)))+imag(dots.v(id(i)))*p.dt,walls))
            v = v - 2*imag(v)*sqrt(-1);
        end
        dots.pos(id(i)) = dots.pos(id(i)) - dots.v(id(i))*p.dt;
        dots.v(id(i)) = v;        
    end
    
    % dots have a force to attract speed toward p.speed
    dots.v = dots.v + p.kSpeed*(p.speed-abs(dots.v)).*exp(sqrt(-1)*angle(dots.v));
    
    % infect!
    bump = abs(z)<p.infectDist - eye(p.nDots);  % list of dots that have collided
    [from,to] = ind2sub([p.nDots,p.nDots],find(bump));
    for i=1:length(from)
        if dots.state(from(i))==2 & dots.state(to(i))==1
            if rand(1)<p.infectProb
                dots.state(to(i))=2;
                dots.ti(to(i))=exprnd(p.infectDur);
                if p.draw
                    dots.col(to(i),:) = colList{2};
                    set(h,'CData',dots.col);
                end
            end
        end
    end
    
    % Recover or Die
    dots.ti(dots.state==2) = dots.ti(dots.state==2) - p.dt;
    
    id = find(dots.ti<0 & dots.state==2);
    for i=1:length(id)
        prob = floor(rand(1)+p.dead);
        if prob==0   % recover
            dots.state(id(i)) = 3;
            if p.draw
                dots.col(id(i),:) = colList{3};
                set(h,'CData',dots.col);
            end
        else  % die
            dots.state(id(i)) = 4;
            dots.v(id(i)) = 0;
            if p.draw
                dots.col(id(i),:) = colList{4};
                set(h,'CData',dots.col);
            end
        end
    end
    
    % Save current values of S,I,R and D
    S(tcount) = sum(dots.state==1);
    I(tcount) = sum(dots.state==2);
    R(tcount) = sum(dots.state==3);
    D(tcount) = sum(dots.state==4);
    title(sprintf('Day %d',floor(t(tcount))));
end
toc
disp(sprintf('frame rate: %5.2f',tcount/toc));
if tcount<length(t)
    S(tcount:end) = S(tcount);
    I(tcount:end) = I(tcount);
    R(tcount:end) = R(tcount);
    D(tcount:end) = D(tcount);
end

%% Plot time-course of S,I,R and D
figure(2)
clf
hold on
plot(t,S,'b-');
plot(t,I,'r-');
plot(t,R,'g-');
plot(t,D,'k-');
legend({'Susceptible','Infected','Recovered','Dead'});
xlabel('Time (days)');
ylabel('People');
set(gca,'XLim',[0,t(tcount)]);
%% Time courses on log y-axis
figure(3)  %
clf
hold on
plot(t,log(S),'b-');
plot(t,log(I),'r-');
plot(t,log(R),'g-');
plot(t,log(D),'k-');
legend({'Susceptible','Infected','Recovered','Dead'});
set(gca,'YTick',log(2.^[0:20]));
logy2raw(exp(1),0);
xlabel('Time (days)');
ylabel('People');
set(gca,'XLim',[0,t(tcount)]);


