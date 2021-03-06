%% ENPH 455 Hybrid Rocket Motor Design Project (Iterative Code)
%Written by: Cole Mero 
%October 29, 2019

clear all
%% Initiate Variables for Simulation 

% Variables for Comparison to Research Paper (comment or uncomment)
%https://pdfs.semanticscholar.org/b004/f9574f56c810273f5bbf7e494ad3598abdae.pdf
% finalD = 0.041;      %[m]    Maximum possible diameter of the motor after completed burn
% initialD = 0.025;    %[m]    Initial diameter of combustion port, pre-burn 
% Lp = 0.57;           %[m]    Length of the combustion port 
% m_ox = 0.304;        %[kg/s] Oxidizer flow rate (from HTPB vs ABS paper)
% throatR = 0.0082;    %[m]    Radius of the nozzle throat
% exitR = 0.0172;      %[m]    Radius of the nozzle exit 

%Variables for Mini-Hybrid Prediction (comment or uncomment) 
finalD = 0.0254;     %[m]    Maximum possible diameter of the motor after completed burn 
initialD = 0.00859;  %[m]    Initial diameter of combustion port, pre-burn 
Lp = 0.121;          %[m]    Length of the combustion port 
m_ox = 0.0123;       %[kg/s] Oxidizer flow rate (experimentally measured)
throatR = 0.0014;    %[m]    Radius of the nozzle throat
exitR = 0.00455;     %[m]    Radius of the nozzle exit 

%Caclulated initial variables for simulation 
A_t = pi*(throatR)^2; %[m^2]  Specify the nozzle throat area 
A_e = pi*(exitR)^2;   %[m^2]  Calculate the nozzle exit area
epsilon = A_e/A_t;    %Nozzle area expansion ratio

rho = 975;           %[kg/m^3]  Average density of ABS plastic 
m_fuel = 0;          %[kg/s]  Fuel flow rate (intialized to 0 for simulation)
lamda = 0.97;        %Nozzle efficiency 
Pa = 101325;         %[Pa] Ambient pressure 
R = 8314.41/29.19;   %[J/kmol*K] Universal gas constant divided by MM of combustion products
dt = 0.1;            %[s] Differential time step to be used for each iteration
G_tot = [];          %Initialize G_tot array to store the instantaneous G values


%% Begin Simulation 
currentD = initialD; %To begin set the diameter to initial (unburnt) diameter

j = 1;

while currentD < finalD

%Calculate the regression rate using custom RegRate function 
[regRate, m_fuel, G_tot(j)] = RegRate(m_ox, currentD, rho, Lp); 
 
%Calculate the new combustion port diameter
currentD = currentD + 2*regRate*dt %Unmuted to check progress/speed of sim

%Calculate the total propellant mass flow
m_tot = m_ox + m_fuel; 

%Caculate the OF ratio 
OF_ratio(j) = m_ox/m_fuel; 

%Using the OF ratio, consult paper
%https://pdfs.semanticscholar.org/a15a/a1b29fffeebfcdb70965e4241af07eb5f00f.pdf
%to get the characteristic velocity for this OF ratio OR use RPA and derive
%them all yourself (this is a good way to do it) and it will also yield the
%flame temp, ratio of specific heats, and molecular mass of the
%combustion products

%Values from RPA for research paper (uncomment or comment)
c_star = 1605;      %[m/s] 
gamma = 1.1708;     %Ratio of specific heats (Cp and Cv idk which order) from RPA
molMass = 0.002919; %[kg/mol] Average molar mass of the output exhaust
Tc = 3301.8;        %[K] Flame temperature (also used as combustion chamber stagnation temp)
 
%Values from RPA for mini-hybrid  (uncomment or comment)
% c_star = 1559;      %[m/s] 
% gamma = 1.2015;     %Ratio of specific heats (Cp and Cv idk which order) from RPA
% molMass = 0.002992; %[kg/mol] Average molar mass of the output exhaust
% Tc = 3321.8;        %[K] Flame temperature (also used as combustion chamber stagnation temp)

%Calcualte the pressure in combustion chamber in Pascals and PSI
pressure_Chamber_Pa(j) =  c_star*m_tot/A_t; %[Pa]
Pc(j) = pressure_Chamber_Pa(j); 
pressure_Chamber_PSI = pressure_Chamber_Pa(j)*0.000145038; %[PSI]

%Calcualte the exit Mach number, to do so use eqn 3.100 from SPAD
%(Humble)and solve it numerically 
syms x
Me = double(vpasolve(epsilon^(2*(gamma-1)/(gamma+1)) == (2/(1+gamma))*...
    (x)^(-2*(gamma-1)/(gamma+1)) + ((gamma-1)/2)*x^(2*(1-...
    ((gamma-1)/(gamma+1)))), x)); 

%Calculate the exit pressure, use eqn 3.95 from SPAD (Humble), with the
%previously determined chamber pressure as the stagnation pressure 
Pe = Pc(j)*(1+((gamma-1)/2)*Me^2)^-(gamma/(gamma-1)); %[Pa]

%Calculate the exit exhaust temperature to determine the exit velocity,
%given by eqn 3.94 from SPAD (Humble)
Te = ((1 + (((gamma-1)/2)*Me^2))^-1)*Tc; 

%Caclualte the exit velocity using eqn 3.112 from SPAD (Humble), using the 
%exit temperature from above
Ve = sqrt(((2*gamma*R*Te)/(gamma-1))*(1-(Pe/Pc(j)))^((gamma-1)/gamma)); %[m/s]

%Now calculate the theoretical thrust of the motor using eqn 1.6 from SPAD
thrust(j) = lamda*(m_tot*Ve + (Pe-Pa)*A_e); %[N]

if j == 1
    time(j) = 0; %Ensure simulation starts at t=0
else
    time(j) = time(j-1) + dt;
end

j = j+1; 
end 

%% Plot the Simulation Results

figure(1)
plot(time+1, Pc) %Shift curve one second right for viewing purposes
title("Combustion Chamber Pressure vs Time")
xlabel("Time [s]")
ylabel("Chamber Pressure [Pa]")
axis([0, 35, 0, 4e6]) %Uncomment for mini-hybrid
% axis([0,12,0,4e6]) %Uncomment for research paper
grid on


figure(2)
plot(time+1, thrust) %Shift curve one second right for viewing purposes
title("Thrust vs Time")
xlabel("Time [s]")
ylabel("Thrust [N]")
axis([0, 35, 0, 40]) %Uncomment for mini-hybrid
% axis([0,12, 0, 1.1e3])%Uncomment for research paper
grid on

figure(3)
plot(time+1, OF_ratio) %Shift curve one second right for viewing puposes 
title("OF Ratio vs Time")
xlabel("Time [s]")
ylabel("OF Ratio")
