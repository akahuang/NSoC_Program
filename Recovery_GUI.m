function varargout = Recovery_GUI(varargin)
% RECOVERY_GUI M-file for Recovery_GUI.fig
%      RECOVERY_GUI, by itself, creates a new RECOVERY_GUI or raises the existing
%      singleton*.
%
%      H = RECOVERY_GUI returns the handle to a new RECOVERY_GUI or the handle to
%      the existing singleton*.
%
%      RECOVERY_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RECOVERY_GUI.M with the given input arguments.
%
%      RECOVERY_GUI('Property','Value',...) creates a new RECOVERY_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Recovery_GUI_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Recovery_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Recovery_GUI

% Last Modified by GUIDE v2.5 28-Dec-2011 13:20:51

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Recovery_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Recovery_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


function Recovery_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
    handles.output = hObject;

    clc;
    handles.fCount = 0;

    load('filtcoef');
    handles.gbp = gbp60;
    handles.sosbp = sosbp60;
    handles.lp = lp60;
    handles.figdat = 0;
    initialize(hObject, eventdata, handles);
    set(handles.figure1, 'CloseRequestFcn', @closeGUI);
    guidata(hObject, handles);

    % UIWAIT makes Recovery_GUI wait for user response (see UIRESUME)
    % uiwait(handles.figure1);

% --- Outputs from this function are returned to the command line.
function varargout = Recovery_GUI_OutputFcn(hObject, eventdata, handles) 
% Get default command line output from handles structure
    varargout{1} = handles.output;

    % --- handles.plotStart_pushbutton --- %
    % 'UserData' ----- (1) idle (2) running (3) pause (4) terminate
    % 'String' ----- (1) Start (2) Pause

    % --- handles.plotStop_pushbutton --- %
    % 'UserData' ----- Start time of the file #1

function plotStart_pushbutton_Callback(hObject, eventdata, handles)
    % system call
    if strcmp(get(handles.plotStart_pushbutton, 'UserData'), 'idle')
        system('start multichannel_moduled_oscilloscope.exe');
        % (strcmp(get(handles.plotStart_pushbutton, 'UserData'), 'terminate'))
        % ||...
    end
    % set state
    if strcmp(get(handles.plotStart_pushbutton, 'UserData'), 'running')
        set(handles.plotStart_pushbutton, 'UserData', 'pause');
        set(handles.plotStart_pushbutton, 'String', 'Start');
        set(handles.message_staticText, 'String', 'Message: Pause!');
        guidata(hObject, handles);
        return;
    else
        set(handles.plotStart_pushbutton, 'String', 'Pause');
        set(handles.plotStart_pushbutton, 'BackgroundColor', [0.68 0.92 1]);
        set(handles.plotStart_pushbutton, 'UserData', 'running');
        guidata(hObject, handles);
    end

    % search for data
    start_time = get(handles.plotStop_pushbutton,'UserData');
    if handles.fCount > 0
        handles.fCount = ceil(get_current_timeslot() - start_time);
    else
        while exist(get_filename(1), 'file') ~= 2
            if (strcmp(get(handles.plotStart_pushbutton, 'UserData'), 'terminate')) || ...
                    (strcmp(get(handles.plotStart_pushbutton, 'UserData'), 'pause'))
                return;
            end
            disp('file not exist');
            pause(5);
        end
        pause(5);
        start_time = get_current_timeslot();
        handles.fCount = 1;
    end

    % read and process
    while (strcmp(get(handles.plotStart_pushbutton, 'UserData'), 'running'))
        mytimer0 = get_current_timeslot() - start_time;
        handles.fCount = last_file(hObject, handles.fCount, handles);
        fname = get_filename(handles.fCount);
        plot_one_fig(hObject, fname, handles);
        mytimer = get_current_timeslot() - start_time;
        if mytimer - mytimer0 < 0.9
            pause(mod(mytimer, 1)*10+1);disp(mod(mytimer, 1)*10+1);
        end
    end
    set(handles.plotStart_pushbutton, 'String', 'Start');
    guidata(hObject, handles);

function plotOne_pushbutton_Callback(hObject, eventdata, handles)
    handles.fCount = handles.fCount+1;
    guidata(hObject, handles);
    if plot_one_fig(hObject, eventdata, handles)
        handles.fCount = handles.fCount-1;
        disp('no more file');
    end
    set(handles.plotStart_pushbutton, 'UserData', 'pause');
    message = sprintf('Message: #%d', handles.fCount);
    set(handles.message_staticText, 'String', message);
    guidata(hObject, handles);

function previous_pushbutton_Callback(hObject, eventdata, handles)
    handles.fCount = max(handles.fCount-1, 1);
    guidata(hObject, handles);
    plot_one_fig(hObject, eventdata, handles);
    set(handles.plotStart_pushbutton, 'UserData', 'pause');
    message = sprintf('Message: #%d', handles.fCount);
    set(handles.message_staticText, 'String', message);
    guidata(hObject, handles);

function plotStop_pushbutton_Callback(hObject, eventdata, handles)
    system('taskkill /im multichannel_moduled_oscilloscope.exe /f');
    handles.fCount = 1;
    axes(handles.axes1);
    cla;
    initialize(hObject, max(handles.fCount-2, 1), handles);
    set(handles.message_staticText, 'String', 'Message: Ready!');
    set(handles.plotStart_pushbutton, 'String', 'Start');
    set(handles.plotStart_pushbutton, 'UserData', 'terminate');
    set(handles.plotStart_pushbutton, 'BackgroundColor', 'green');
    guidata(hObject, handles);

function er = plot_one_fig(hObject, fname, handles)
    if isempty(fname)
        fname = get_filename(handles.fCount);
    end
    if exist(fname, 'file') ~= 2
        er = 1;
        return;
    end
    er = 0;
    tic;
    xx = load(fname);
    sample_rate = 1/(xx(2, 1)-xx(1,1));
    xx = data_clean(hObject, xx, handles);
    A_m = size(xx,2);
    xx = xx(:,2:A_m)';
    if numel(xx)==0, return; end
    A_m = A_m-1;
    A_n = 1;
    eta = 0.003;
    fig = 0;
    L = 10;
    fil = 1;
    for aa=1:A_m
        xx(aa,:) = filter(handles.lp, 1, xx(aa,:));
        xx(aa,1:length(handles.lp)) = xx(aa,length(handles.lp)+1);
    end
    size_xx = size(xx);
    T = size_xx(2);
    tau_s = 0; tau_n = 2; tau_space=0.2;
    switch get(handles.alg_popupmenu, 'Value')
        case 1      % SOBI
            [~, s_hat_all, s_hat_blood] = ...
                SOBIseparationBeta(xx, A_n, A_m, T, sample_rate, tau_s, tau_n, tau_space, fig);
        case 2      % Multi-channel
            [~, s_hat_all, s_hat_blood] = ...
                MultichannelDeconvolution(xx, A_n, A_m, T, eta, L, sample_rate, fig, fil);
        case 3
            s_hat_all = xx(1, :);
            s_hat_blood = 1;
    end
    temptoc = toc;

    message = sprintf('Message: #%d (%d sec)', handles.fCount, temptoc);
    set(handles.message_staticText, 'String', message);

    S_hat = s_hat_all(s_hat_blood, :)-mean(s_hat_all(s_hat_blood,:));
    if sum(sign(diff(S_hat)))>0; S_hat = -S_hat; end
    if sum(isnan(S_hat))==0
        p=zeros(1, T/sample_rate);
        for aa=1:T/sample_rate
            [dummy p(aa)] = min(S_hat(sample_rate*(aa-1)+1:aa*sample_rate));
            p(aa) = p(aa)+sample_rate*(aa-1);
        end
        p = floor(p(2:2:length(p)));
        if length(p)>=2
            s = spline([-sample_rate/10 p T+sample_rate/10], [S_hat(p(1)) S_hat(p) S_hat(p(length(p)))], 1:T);
        end
        S_hat = S_hat-s;
        p=zeros(1, T/sample_rate);
        for aa=1:T/sample_rate
            [dummy p(aa)] = max(S_hat(sample_rate*(aa-1)+1:aa*sample_rate));
            p(aa) = p(aa)+sample_rate*(aa-1);
        end
        p = floor(p(1:length(p)));
        if length(p)>=2
            s = spline([-sample_rate p T+sample_rate], [S_hat(p(1)) S_hat(p) S_hat(p(length(p)))], 1:T);
        end
        S_hat = S_hat./s;
    end
    S_hat = S_hat/sqrt(var(S_hat));
    fname = get_filename(handles.fCount, 'NSoC_r_');
    save(fname, 'S_hat', '-ASCII');
    axes(handles.axes1);
    plot((0:T-1)/sample_rate, S_hat);
    xlabel('time (s)'); ylabel('V');
    guidata(hObject, handles);

function alg_popupmenu_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function alg_popupmenu_CreateFcn(hObject, eventdata, handles)
    if ispc && isequal(get(hObject, 'BackgroundColor'), get(0, 'defaultUicontrolBackgroundColor'))
        set(hObject, 'BackgroundColor', 'white');
    end

function closeGUI(src, evnt)
%src is the handle of the object generating the callback (the source of the event)
%evnt is the The event data structure (can be empty for some callbacks)
    selection = questdlg('Do you want to close the GUI?', ...
                         'Close Request Function', ...
                         'Yes', 'No', 'Yes');
    %delete('*.txt');
    switch selection,
       case 'Yes',
        delete(gcf)
       case 'No'
         return
    end

% --- Other Functions --- %
function initialize(hObject, eventdata, handles)
    tempCount = last_file(hObject, eventdata, handles);
    set(handles.message_staticText, 'String', 'Message: System is Ready!');
    set(handles.plotStart_pushbutton, 'UserData', 'idle');
    timeStart = get_current_timeslot() - tempCount + 2;
    set(handles.plotStop_pushbutton, 'UserData', timeStart);
    guidata(hObject, handles);

function y = data_clean(hObject, x, handles)
    thM = 256*5/6;
    thm = 256/6;
    thrange = 256/25; %0.5
    sx = size(x);
    count = 1:sx(2);
    ma = max(x);
    mi = min(x);
    lr = mean(x(sx(1)/2:sx(1),:))-mean(x(1:sx(1)/2,:));
    Mm = ma-mi;

    take = abs(lr./Mm)<0.3 & Mm>thrange & ma<thM & mi>thm;
    take(1) = 1;
    y = x(:, count(take>0));

function y = last_file(hObject, eventdata)
% Binary search the index of the last file?
    count = 1;
    if ~isempty(eventdata)
        count = eventdata;
    end;
    lo = count;
    maxN = 999;
    up = count+1;
    while 1
        if lo >= up; break; end
        count = floor((lo+up)/2);
        if exist(get_filename(up), 'file') == 2
            lo = up;
            up = min(2*lo, maxN);
        elseif exist(get_filename(lo), 'file') ~= 2
            up = lo-1;
            lo = max(0, floor(up/2));
        elseif exist(get_filename(count), 'file') == 2
            if up-lo == 1, break; end
            lo = count;
        else
            if up-lo == 1, lo = up; break; end
            up = count;
        end
    end
    y = max(lo, 1);

function y = get_current_timeslot(unit)
% Get the index of current time slot
    if ~exist('unit', 'var'), unit = 10; end

    weight = [0 0 86400 3600 60 1]';
    y = clock * weight / unit;

function filename = get_filename(count, prefix)
    if ~exist('prefix', 'var'), prefix = 'NSoC_'; end
    suffix = '.txt'
    filename = sprintf('%s%03d%s', prefix, count, suffix);
