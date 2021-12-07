% This script reads in multiple .mat files used to create surfaceplots over time.

%=========================================================================%
% Patrick Horve + Raghu Parthasarathy - Fall 2021
%=========================================================================%

% Prompt setup for working directory
clear
prompt = {'\fontsize{15} Please enter absolute path to parent directory (There should be a folder in this parent directory named "Fish1"):'};
opts.Interpreter = 'tex';
Title = 'Attention!';
defaultans = {''};
userpath = inputdlg(prompt,Title,[1 75], defaultans, opts);

cd (startpath); %path to the folder that holds all the .tif stacks
mkdir("surfaceplots_threshold")
mkdir("IntensityXPosition_threshold")
mkdir("surfaceplots_mean")
mkdir("IntensityXPosition_mean")

% Level subtracted analysis
% 5. Start looping through the timepoints
for t = 1:timepoints
    cd surfaceplot_stacks_levelsubtract
    s = load("surfaceplot_stack-"+t+".mat");
    stack_xy = s.stack_xy;
    % Make the figure
    fig1 = figure; surf(stack_xy); shading interp
    caxis([-1000 10000]) % for example, to adjust it
    zlim([-1000 10000])
    view([-39.3 58.2412])
    xlabel('x, \mum')
    ylabel('y, \mum')
    title(sprintf('%.1f hours', t/6))
    colorbar

    stack_y = sum(stack_xy,2);
    fig2 = figure; plot(scale_xy*(1:length(stack_y)), stack_y)
    xlabel('y position, microns')
    ylabel('Intensity (summed)')
    cd ../
    cd surfaceplots_threshold
    % Save the fgiure
    saveas(fig1, ("surfaceplot-"+t+".png"))
    close(fig1)
    cd ../
    cd IntensityXPosition_threshold
    saveas(fig2, ("IntensitybyPosition-"+t+".png"))
    close(fig2)
    cd ../
    plot(scale_xy*(1:length(stack_y)), stack_y, '.'); hold on
end
hold off

% Mean subtracted analysis  figures
for t = 1:timepoints
    cd surfaceplot_stacks_meansubtract
    s = load("surfaceplot_stack-"+t+".mat");
    stack_xy = s.stack_xy_mean;
    % Make the figure
    fig1 = figure; surf(scale_xy*(1:size(stack_xy,2)), scale_xy*(1:size(stack_xy,1)), stack_xy); shading interp
    caxis([-1000 10000]) % for example, to adjust it
    zlim([-1000 10000])
    view([-39.3 58.2412])
    xlabel('x, \mum')
    ylabel('y, \mum')
    title(sprintf('%.1f hours', t/6))
    colorbar

    stack_y = sum(stack_xy,2);
    fig2 = figure; plot(scale_xy*(1:length(stack_y)), stack_y)
    xlabel('y position, microns')
    ylabel('Intensity (summed)')
    cd ../
    cd surfaceplots_mean
    % Save the fgiure
    saveas(fig1, ("surfaceplot-"+t+".png"))
    close(fig1)
    cd ../
    cd IntensityXPosition_mean
    saveas(fig2, ("IntensitybyPosition-"+t+".png"))
    close(fig2)
    cd ../
    plot(scale_xy*(1:length(stack_y)), stack_y, '.'); hold on
end
hold off
