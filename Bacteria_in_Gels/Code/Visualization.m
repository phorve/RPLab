% for_overall_intensity_plot.m
% Raghuveer Parthasarathy
% Dev. 4, 2021

MATdirectory = '/Users/patrick/Dropbox (University of Oregon)/mat';
cd(MATdirectory)

%% Load data

load('Control_series_data.mat')
t_hrs_Control = (1/6)*final_data1.Timepoint; % time, hours
sumIntensity_Control = final_data1.sumRegionIntensity;
nColonies_Control = final_data1.objects;

load('TB_series_data.mat')
t_hrs_TB = (1/6)*final_data2.Timepoint; % time, hours
sumIntensity_TB = final_data2.sumRegionIntensity;
nColonies_TB = final_data2.objects;

%% Make plots
figure('name', 'TotalIntensty', 'position', [50 200 560 420]); 
semilogy(t_hrs_Control, sumIntensity_Control, 'o-', 'markersize', 6)
hold on
semilogy(t_hrs_TB, sumIntensity_TB, 'o-', 'markersize', 6)
axis([0 8.25 1e5 2e11])
xlabel('Time, hours')
ylabel('Total intensity, a.u.')
legend('Control', 'TB', 'location', 'NW')

figure('name', 'Number of objects', 'position', [100 200 560 420]); 
semilogy(t_hrs_Control, nColonies_Control, 'o', 'markersize', 6)
hold on
semilogy(t_hrs_TB, nColonies_TB, 'o', 'markersize', 6)
axis([0 8.25 10 1e5])
xlabel('Time, hours')
ylabel('Number of colonies')
legend('Control', 'TB', 'location', 'NW')

figure('name', 'Intensity / Objects', 'position', [150 200 560 420]); 
semilogy(t_hrs_Control, sumIntensity_Control./nColonies_Control, 'o', 'markersize', 6)
hold on
semilogy(t_hrs_TB, sumIntensity_TB./nColonies_TB, 'o', 'markersize', 6)
axis([0 8.25 1e4 1e7])
xlabel('Time, hours')
ylabel('Intensity per colony (a.u.)')
legend('Control', 'TB', 'location', 'NW')

%% Fitting the growth rate

% params0 = [5 1e11 1e8 5.75];
% [r, K, N0, t_lag, sigr, sigK, sigN0, sigt_lag] = fit_logistic_growth(t_hrs_Control, sumIntensity_Control, false,...
%          [], [], params0, [], [], [], true);

