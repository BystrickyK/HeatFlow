%%close all, clear allalpha = 0.05;dx = 0.05;dt = 0.0125;k = 74; % thermal conductivity of iron [W/mK]cp = 0.45; % specific heatrho = 7800; % kg/m^3alpha = k / (cp * rho);  % thermal diffusivityFo = alpha * dt / dx^2; % Fourier numberBy = dt / (cp*rho*dx^2); %%% Set up modelside_elements = 20; % number of elements on each siden_elements = side_elements^2;% Create a general 2D-plate heat transfer modelsys = create_model_fnum(side_elements, Fo, By);  % Specify the Fourier number and set up time-stepping schemeT_forward = sys;  % Input T_k, output T_k+1% Function to reshape vector to an image arrayreshape_T = @(T) reshape(T, [side_elements, side_elements]);reshape_T_back = @(Tk) reshape(Tk, [n_elements, 1]);% Vector of initial node temperaturesimg = imread('ball.png');img = rgb2gray(img);img = imresize(img, [side_elements, side_elements]);img = 255-img;img = img./255*10;img = img .* 0;i = 1:1:side_elements;img(end, :) = 0;img(:, end) = 0;img(:, 1) = 0;img(1, :) = 0;Timg_idx = img .* 0;Timg_idx(end, :) = 1;Timg_idx(:, end) = 1;Timg_idx(:, 1) = 1;Timg_idx(1, :) = 1;Timg_idx = Timg_idx > 0.5;Timg = double(reshape(img, [n_elements, 1]));Timg_idx = reshape(Timg_idx, [n_elements, 1]);T = Timg;%% Simulatestamp = string(round(rand()*100));% stamp = 'edge_setTemp';savename = string(side_elements) + '_' + stamp;s = [10, 10];R = 1;  % laser point sizeI=[];J=[];I2=[];J2=[];if isfile(savename + '.mat')    disp("Loading solution for stamp: " + stamp)    file = load(savename);    simdata = file.simdata;else    disp("Calculating solution for stamp: " + stamp)    simdata = {};    simdata{end+1} = T;    Tk = T;    k_steps = 500;        for k = 1:k_steps%        Tk = simdata{end};       Tk = reshape_T(Tk);%        r = k/k_steps*80;%        r = 8*sin(0.12*k);       r = 8;       j = round(s(1)+r*cos(0.02*k));       i = 2;%        j = round(s(2)+r*sin(0.03*k));%        i2 = round(s(1)+r*cos(0.03*k+pi));%        j2 = round(s(2)+r*sin(0.03*k+pi));              Tk(i-R:i+R, j-R:j+R) = 50;%        Tk(i2-R:i2+R, j2-R:j2+R) = 50;       Tk = reshape_T_back(Tk);              % "boundary" conditions%        Tk(Timg_idx) = Timg(Timg_idx);  % Sets constant temperature              % time step forward       Tk = T_forward(Tk);       if mod(k,1)==0        simdata{end+1} = Tk;       end       maxabs = max(abs(Tk));       disp([k, maxabs])       I(end+1)=i;       J(end+1)=j;%        I2(end+1)=i2;%        J2(end+1)=j2;       if maxabs>1e6           error('Model unstable')       end    end%     save(savename, 'simdata', 'dt', 'dx', 'alpha')end%% Visualization% Reshape the vector of node temperatures into a 2D array for plottingTk = reshape_T(T);[X, Y] = meshgrid(0:dx:side_elements*dx-dx, 0:dx:side_elements*dx-dx);f = figure('Position', [0 0 1000 1000]);ax1 = gca;% splot = surfc(ax1, X, Y, Tk, 'facealpha', 0.85);[m, splot] = contourf(ax1, X, Y, Tk);% splot(1).FaceColor = 'interp';% splot(1).EdgeColor = 'none';% splot(1).EdgeAlpha = 1;% splot(2).LevelStep = 0.25;splot.LevelStep = 1;splot.LevelList = [0:0.5:50];splot.LineColor = 'none';axis equalhold onax1.ZLimMode = 'manual';ax1.ZLim = [0 50];   % Z limit is constantax1.CLim = [0 50];  % Colorbar rangeax1.XLabel.String = 'X';ax1.XLabel.FontSize = 16;ax1.YLabel.String = 'Y';ax1.YLabel.FontSize = 16;% ax1.ZLabel.String = 'T';% ax1.ZLabel.FontSize = 16;colorbarcolormap(hot)% gradfun = @(T) gradient(T, dx);% [gradX, gradY] = gradfun(Tk);% norms = arrayfun(@(x,y)norm([x,y]), gradX, gradY);% gradX_ = gradX./norms;% gradY_ = gradY./norms;% g1 = quiver3(ax1, X, Y, Tk, -gradX, -gradY, X.*0);% g1.AutoScale = 'on';% g1.AutoScaleFactor = 0.5;hold offset(gca,'LooseInset',get(gca,'TightInset'));% view(360, 90)% g1.Visible = 'off';% drawnowframes = [getframe(f)];L = length(simdata);% t = round(logspace(-2, 0, L/10)*L);t = round(linspace(1, length(simdata), 300));t = t - t(1) + 1;framenum = 0;azim = 0;elev = 0;for k = t    framenum = framenum + 1;    T = simdata{k};    Tk = reshape_T(T);            splot.ZData = Tk;%     splot(1).ZData = Tk;%     splot(2).ZData = Tk;%     [gradX, gradY] = gradfun(Tk);%     norms = arrayfun(@(x,y)norm([x,y]), gradX, gradY);%     gradX_ = gradX./norms;%     gradY_ = gradY./norms;%     g1.ZData = Tk;%     g1.UData = -gradX;%     g1.VData = -gradY;%     g1.WData = (-gradX*dx + -gradY*dx);%     g1.WData = 0;    title(k*dt);%     azim = azim + 0.1*sin(3*framenum)^2;%     elev = elev - 0.2*sin(2*framenum)^2;%     view(360+azim, 90+elev)    drawnow    frames(end+1) = getframe(f);   endwriterObj = VideoWriter('anim2');writerObj.FrameRate = 20;open(writerObj);for k = 2:length(frames)   frame = frames(k);   writeVideo(writerObj, frame);endclose(writerObj);