clc;
clear;
close all;
%% Problem Definition
% Inflow Importing
inflow = xlsread ('Data','Inflow','B2:M7');
[r , c] = size(inflow);
T = r*c;
inflow = reshape(inflow',1,T);

% Demand Importing
d = xlsread ('Data','Demand','B2:M6');
demand.urban = d(1,:);
demand.field = d(2,:);
demand.env = d(3,:);
demand.et = d(5,:);
sharge = d(4,:);

% Convert Unit
for i = 1:12
    if (i <= 6)
        demand.urban(i) = demand.urban(i) *31*24*3600;    %m^3
        demand.field(i) = demand.field(i) *31*24*3600;    %m^3
    elseif (i < 12)
        demand.urban(i) = demand.urban(i) *30*24*3600;    %m^3
        demand.field(i) = demand.field(i) *30*24*3600;    %m^3
    else
        demand.urban(i) = demand.urban(i) *29*24*3600;    %m^3
        demand.field(i) = demand.field(i) *29*24*3600;    %m^3
    end
end
for i = 1:T
    if (rem(i,12) <= 5)
        inflow(i) = inflow(i) *31*24*3600;    %m^3
    elseif (rem(i,12) < 11)
        inflow(i) = inflow(i) *30*24*3600;    %m^3
    else
        inflow(i) = inflow(i) *29*24*3600;    %m^3
    end
end
demand.env = demand.env * 10e5;
sharge = sharge * 10e5;


% G(s) Importing
gs = xlsread ('Data','g(s)','B1:N3');
g.h = gs(1,:);
g.v = gs(2,:);
g.a = gs(3,:);

% Initial value
smin = 100*10e5;
sini = 420*10e5;
Ka = 420*10e5;

% Pre-allocation
s = zeros(1,T);
r = zeros(1,T);
H = zeros(1,T);
H(1) = 1780;
%% Main Loop
s (1) = sini;
for t = 1:T
    month = rem(t,12) + 1;
    r(t) = demand.urban(month) + demand.field(month) + demand.env(month);
    s(t+1) = s(t) + inflow(t) + sharge(month) - r(t);
    a = s(t+1)*10;
    while (abs(s(t+1) - a) > s(t+1)/10)
        a = s(t+1);
        for i = 1:12
            if (g.v(i) <= (s(t+1)+s(t))/2)
                A = g.a(i) + ((g.a(i+1)-g.a(i))...
                    /(g.v(i+1)-g.v(i)))*((s(t+1)+s(t))/(2*10e5) - g.v(i));
            end
        end
        s(t+1) = s(t) + inflow(t) + sharge(month)...
            - r(t) - demand.et(month)*A*1000;
        if (s(t+1) < smin)
            r(t) = r(t) - (smin - s(t+1));
            s(t+1) = smin;
        elseif (s(t+1) > Ka)
            r(t) = r(t) + (s(t+1) - Ka);
            s(t+1) = Ka;
        end
    end
    for i = 1:12
        if (g.v(i) <= s(t))
            H(t) = g.h(i) + ((g.h(i+1)-g.h(i))...
                /(g.v(i+1)-g.v(i)))*(s(t)/10e5 - g.v(i));
        end
    end
end

%% Result
figure
grid on;
plot (1:T,inflow,'b');
xlabel('Time (month)');
ylabel('Inflow (Cube Meter)')

figure
plot (1:T,r,'r');
xlabel('Time (month)');
ylabel('Release (Cube Meter)')

figure
plot (1:T,s(1:T),'g');
xlabel('Time (month)');
ylabel('Storage (Cube Meter)')

figure
plot (1:T,H,'y');
xlabel('Time (month)');
ylabel('Height of Water (Meter)')