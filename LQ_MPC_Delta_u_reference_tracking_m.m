%%close all, clear allalpha = 0.05;dx = 0.05;dt = 0.075;k = 74; % thermal conductivity of iron [W/mK]k = k * 0.25;cp = 0.45; % specific heatrho = 7800; % kg/m^3alpha = k / (cp * rho);  % thermal diffusivityFo = alpha * dt / dx^2; % Fourier numberBy = dt / (cp*rho*dx^2) * 10;loss = 0.001; % loss coefficient [J * K^-1 * s^-1]Co = loss * (cp/rho) * (dt / dx^2); % "environmental heat loss"%%% Set up modelside_elements = 118; % number of elements on each siden_elements = side_elements^2;% Create a general 2D-plate heat transfer model[sys, mats] = create_model_fnum(side_elements, Fo, Co, By);  T_forward = sys;  % Input T_k, u, output T_k+1%%% Function to reshape vector to an image arrayreshape_T = @(T) (reshape(T, [side_elements, side_elements]));% Reshape image array back to a vectorreshape_T_back = @(Tk) reshape(Tk, [n_elements, 1]);% Vector of initial node temperaturesimg = imread('cvut.png');img = rgb2gray(img);img = imresize(img, [side_elements, side_elements]);img = flip(img);img = 255-img;img = img./255;img = double(img);% Set referenceW1 = img * 7;% figure();image(W);colorbar();T = reshape_T_back(img .* 0);% T = T + 20;U = reshape_T_back(img .* 0);W1 = reshape_T_back(W1);U_full = U;% second referenceimg2 = imread('B.png');img2 = rgb2gray(img2);img2 = imresize(img2, [side_elements, side_elements]);img2 = flip(img2);img2 = 255-img2;img2 = img2./255;img2 = double(img2);W2 = img2 * 7;W2 = reshape_T_back(W2);%% Define control parametersA = mats.A;B = mats.B;N = 3; % prediction horizon% Indexes of active inputsactive_inputs = 1:5:n_elements;B = B(:, active_inputs);U = U(active_inputs); n_inputs = length(active_inputs);% n_inputs = floor(n_elements/6);% active_inputs = datasample(1:n_elements, n_inputs, 'Replace', false);% B = B(:, active_inputs);% U = U(active_inputs);% Augment the system to contain current inputA_tilde = sparse([A B; zeros([n_inputs, n_elements]), eye(n_inputs)]);B_tilde = sparse([B; eye(n_inputs)]);C_tilde = sparse([eye(size(A)), zeros(size(B))]);% new input is the input difference (přírůstek) delta_u% Define error weights Q and input change weights RQ = spdiag(n_elements, 0) * 1;R = Q * 1;R = R(active_inputs, active_inputs);% Create Q double barQdbar = spblockdiag(C_tilde' * Q * C_tilde, N, 0);% Create T double barTdbar = spblockdiag(Q*C_tilde, N, 0);% Create R double barRdbar = spblockdiag(R, N, 0);% Create C double bar[blockrows, blockcols] = size(B_tilde);Cdbar = sparse(blockrows*N, blockcols*N);for i = 1:N    Cdbar_ = spblockdiag(A_tilde^i * B_tilde, N, -i+1);    Cdbar = Cdbar + Cdbar_;%     imagesc(Cbar_)%     pause()end% imagesc(Cbar)% Create A double barAdbar = repmat(A_tilde, [N, 1]);% Define H double bar and F double barH = (Cdbar' * Qdbar * Cdbar + Rdbar);F = [Adbar' * Qdbar * Cdbar; -Tdbar * Cdbar]';% Quadprog parametersUhat = repmat(U, N, 1);  % initial guessWhat = repmat(W1, N, 1);  % trajectory (constant)lb = Uhat.*0 - 0.05;ub = Uhat.*0 + 0.25;options = optimoptions(@quadprog, 'Algorithm', 'interior-point-convex', ...    'Display', 'off');%% Simulatestamp = string(round(rand()*10000));% stamp = 'MPC_dU_unbounded_B1000';savename = "results" + filesep + string(side_elements) + "_" + stamp;if isfile(savename + '.mat')    disp("Loading solution for stamp: " + stamp)    file = load(savename);    simdata = file.simdata;else    disp("Calculating solution for stamp: " + stamp)    simdata.T = {};    simdata.T{end+1} = T;    simdata.U = {};    simdata.U{end+1} = U_full;    simdata.E = {};    simdata.E{end+1} = W1-T;        Tk = T;    k_steps = 300;  % how many time steps are simulated        for k = 1:k_steps               % State deviation from reference        E = W1 - Tk;              tic       x_t_tilde = [Tk; U];       f = (F*[x_t_tilde; What]);%        MPC unconstrained%        Uhat = -H\f;       % MPC Quadprog       Uhat = quadprog(H, f,...           [], [],...           [], [],...           lb, ub,...           Uhat, options);%               toc       deltaU = Uhat(1:blockcols);       U = U + deltaU;       U_full(active_inputs) = U;              % time step forward       Tk = T_forward(Tk, U_full);       %        if k==80%            disp(k)%            Tk = reshape_T(Tk);%            T_diag = spdiag(side_elements, -1) + spdiag(side_elements, 0) +...%                spdiag(side_elements, 1);%            T_diag = full(T_diag);%            T_diag = ones(size(T_diag)) - T_diag;%            Tk = Tk .* T_diag;%            Tk = reshape_T_back(Tk);%        end%               if round(rand*5) == 1           disp('pop')            Tk = reshape_T(Tk);            mid = round(side_elements/2);            i = mid + (rand()-0.5)*(mid * 1.5);            j = mid + (rand()-0.5)*(mid * 1.5);            i = round(i);            j = round(j);            i = (-1:1) + i;            j = (-1:1) + j;            Tk(i,j) = Tk(i,j) - 5;            Tk = reshape_T_back(Tk);                   end              % Save current step       if mod(k,1)==0        simdata.T{end+1} = Tk;        simdata.U{end+1} = U_full;        simdata.E{end+1} = E;       end              maxabs = max(abs(Tk));       disp([k, maxabs])       if maxabs>1e6           error('Model unstable')       end           end    save(savename, 'simdata')end%% Visualization% Reshape the vector of node temperatures into a 2D array for plottingTk = reshape_T(T);elements = 0:dx:side_elements*dx-dx;[X, Y] = meshgrid(elements, elements);f = figure('Position', [0 0 1400 1000]);t = tiledlayout(2, 3, 'TileSpacing', 'tight', 'Padding', 'tight');ax1 = nexttile([2,2]);% splot = surfc(ax1, X, Y, Tk, 'facealpha', 0.85);% [m, splot] = contourf(ax1, X, Y, Tk);% splot.LevelStep = 1;% splot.LevelList = [-5:0.125:10];% splot.LineColor = 'none';axis equalsplot = imagesc(flip(Tk));hold onax1.ZLimMode = 'manual';ax1.ZLim = [-6 7];   % Z limit is constantax1.CLim = [-6 7];  % Colorbar rangecolorbarcolormap(jet)hold offax2 = nexttile(3);yyaxis leftylabel('Heat input')powerplot = animatedline(ax2, 'Marker', 'o', 'linewidth', 2, 'color', 'blue');yyaxis rightylabel('Mean error')errorplot = animatedline(ax2, 'Marker', 'o', 'linewidth', 2, 'color', [1,0.55,0]);grid onax3 = nexttile(6);Uk = reshape_T(simdata.U{1});inputimg = image(ax3, elements', elements', flip(Uk, 1));inputimg.CDataMapping = 'scaled';title('Heat input image')    cmap = [zeros(1,128), linspace(0,1,128);        linspace(1,0,128), linspace(0,1,128);        linspace(1,0,128), zeros(1,128)]';    cmap = (cmap.*0+1) - cmap; %invertax3.CLim = [-3, 3];ax3.Colormap = flip(cmap);colorbar()frames = [getframe(f)];L = length(simdata);% t = round(linspace(1, length(simdata.T)*dt, 300));% t = t - t(1) + 1;% k_steps = 300;t = 1:k_steps;framenum = 0;for k = t    disp(k)    framenum = framenum + 1;        T = simdata.T{k};    U = simdata.U{k};    E = simdata.E{k};        Tk = reshape_T(T);    Uk = reshape_T(U);        %     splot.ZData = Tk;%     splot(1).ZData = Tk;    splot.CData = flip(Tk);    addpoints(powerplot, k*dt, sum(U));    addpoints(errorplot, k*dt, mean(E));        inputimg.CData = flip(Uk, 1);        drawnow    frames(end+1) = getframe(f);   endwriterObj = VideoWriter('animation2');writerObj.FrameRate = 20;open(writerObj);for k = 2:length(frames)   frame = frames(k);   writeVideo(writerObj, frame);endclose(writerObj);