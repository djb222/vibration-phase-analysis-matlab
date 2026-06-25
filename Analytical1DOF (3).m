% THEORETICAL SDOF MODEL — CUSSONS RIG #3
% Theoretical phase-response model
% Later evaluated at experimental frequencies for comparison with measured data
% Uses actual rig parameters and forcing frequencies

clc;
clear;
close all;

%% ---------------------------------------------------------
% RIG PARAMETERS
%% ---------------------------------------------------------
m  = 1.437;           % kg
fn = 1.65;            % Hz
wn = 2*pi*fn;         % rad/s

k = m*wn^2;           % spring stiffness (N/m)

fprintf('Spring stiffness k = %.2f N/m\n',k)

%% ---------------------------------------------------------
% EXPERIMENTAL FREQUENCIES
% Experimental forcing frequencies
% Used after testing for direct comparison
%% ---------------------------------------------------------
f_exp = [0.50 0.83 1.16 1.40 1.57 ...
         1.65 1.73 1.90 2.15 ...
         2.48 3.30 4.13];

r_exp = f_exp ./ fn;

w = 2*pi*f_exp;

%% ---------------------------------------------------------
% DAMPING RATIOS
% Approximate mapping to experimental damping
%% ---------------------------------------------------------
zeta_list = [0.003 0.037 0.116 0.26];

%% ---------------------------------------------------------
% THEORETICAL MODEL
%
% Phase:
%
% atan2(2*z*r,1-r^2)
%% ---------------------------------------------------------

phase_theory = zeros(length(zeta_list), length(f_exp));

for i = 1:length(zeta_list)

    zeta = zeta_list(i);

    r = w / wn;

    phase_theory(i,:) = rad2deg( ...
        atan2(2*zeta*r, (1-r.^2)) );

end

%% ---------------------------------------------------------
% PLOT
%% ---------------------------------------------------------

figure('Color','w',...
       'Position',[100 100 900 650])

hold on
grid on
box on

colors = lines(4);

for i = 1:length(zeta_list)

    % smooth otu the curve
    r_smooth = linspace(0,3,3000);

    phi_smooth = rad2deg( ...
        atan2(2*zeta_list(i)*r_smooth,...
        1-r_smooth.^2));

    plot(r_smooth,...
         phi_smooth,...
         'LineWidth',2,...
         'Color',colors(i,:))

end

%% ---------------------------------------------------------
% Format the plot
%% ---------------------------------------------------------

xlabel('Frequency Ratio r = f / f_n')
ylabel('Phase Angle (degrees)')

title('Analytical Phase Response')

legend(...
    '\zeta = 0.003',...
    '\zeta = 0.037',...
    '\zeta = 0.116',...
    '\zeta = 0.26',...
    'Location','southeast')

xlim([0 3])
ylim([0 180])

set(gca,'FontSize',11)

fprintf('Theoretical model generated.\n')