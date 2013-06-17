classdef main < handle
    % main.m class for ecig.m
    % See dated ReadMe file
    
    properties
        exec = 'default'; % Execute type, associated with bin files
        monitor
        path
        exp
        movie
        temp_t
        abort = 0;
        mov
    end
    
    properties (SetObservable)
       dat
    end
    
    events
       fix
       playback
       txt
    end
    
    methods (Static)
        function [monitor] = disp()
            % Find out screen number.
            debug = 1;
            if debug
                %                 whichScreen = max(Screen('Screens'));
                whichScreen = 1;
            else
                whichScreen = 0;
            end
            oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel',0);
            oldOverrideMultimediaEngine = Screen('Preference', 'OverrideMultimediaEngine', 1);
%             Screen('Preference', 'ConserveVRAM',4096);
%             Screen('Preference', 'VBLTimestampingMode', 1);
            
            % Opens a graphics window on the main monitor (screen 0).  If you have
            % multiple monitors connected to your computer, then you can specify
            % a different monitor by supplying a different number in the second
            % argument to OpenWindow, e.g. Screen('OpenWindow', 2).
            [window,rect] = Screen('OpenWindow', whichScreen);
            
            % Screen center calculations
            center_W = rect(3)/2;
            center_H = rect(4)/2;
            
            % ---------- Color Setup ----------
            % Gets color values.
            
            % Retrieves color codes for black and white and gray.
            black = BlackIndex(window);  % Retrieves the CLUT color code for black.
            white = WhiteIndex(window);  % Retrieves the CLUT color code for white.
            
            gray = (black + white) / 2;  % Computes the CLUT color code for gray.
            if round(gray)==white
                gray=black;
            end
            
            gray2 = gray*1.5;  % Lighter gray
            
            % Taking the absolute value of the difference between white and gray will
            % help keep the grating consistent regardless of whether the CLUT color
            % code for white is less or greater than the CLUT color code for black.
            absoluteDifferenceBetweenWhiteAndGray = abs(white - gray);
            
            % Data structure for monitor info
            monitor.whichScreen = whichScreen;
            monitor.rect = rect;
            monitor.center_W = center_W;
            monitor.center_H = center_H;
            monitor.black = black;
            monitor.white = white;
            monitor.gray = gray;
            monitor.gray2 = gray2;
            monitor.absoluteDifferenceBetweenWhiteAndGray = absoluteDifferenceBetweenWhiteAndGray;
            monitor.oldVisualDebugLevel = oldVisualDebugLevel;
            monitor.oldOverrideMultimediaEngine = oldOverrideMultimediaEngine;
            
            Screen('CloseAll');
        end
    end
    
    methods
        function obj = main(varargin)
            ext = [];
            d = [];
            
            % Argument evaluation
            for i = 1:nargin
               if ischar(varargin{i}) % Assume main directory path string
                   ext = varargin{i};
               elseif iscell(varargin{i}) % Assume associated directories
                   d = varargin{i};
               else
                   fprintf(['main.m (main): Other handles required for argument value: ' int2str(i) '\n']);
               end
            end
            
            % Path property set-up
            if isempty(ext) || isempty(d)
                error('main.m (main): Empty path string or subdirectory list.');
            else
                try
                    fprintf('main.m (main): Executing path directory construction...\n');
                    obj.pathset(d,ext);
                    fprintf('main.m (main): obj.pathset() success!\n');
                catch ME
                    throw(ME);
                end
            end
            
            % Display properties set-up
            try
                fprintf('main.m (main): Gathering screen display details (Static)...\n');
                monitor = obj.disp; % Static method
                fprintf('main.m (disp): Storing monitor property.\n');
                obj.monitor = monitor;
                fprintf('main.m (main): obj.disp success!\n');
            catch ME
                throw(ME);
            end
            
            % Experimental properties set-up
            try
                fprintf('main.m (main): Gathering experimental details...\n');
                obj.expset();
                fprintf('main.m (main): obj.expset() success!\n');
            catch ME
                throw(ME);
            end            
            
        end
        
        function [path] = pathset(obj,d,ext)
            if all(cellfun(@(y)(ischar(y)),d))
                for i = 1:length(d)
                    path.(d{i}) = [ext filesep d{i}];
                end
                fprintf('main.m (pathset): Storing path property.\n');
                obj.path = path;
            else
                error('main.m (pathset): Check subdirectory argument.')
            end
        end
        
        function [exp] = expset(obj)
            % Load
            head_f = ['head_' obj.exec]; % MAT file type
            
            fprintf('main.m (expset): Reading header information -- %s.\n', head_f);
            load([obj.path.bin filesep head_f]);
            headnames = fieldnames(eval(head_f));
            
            % Fail-safe
            if length(headnames) > 2
                error('main.m (expset): More than two types of headers is unsupported.')
            end
            
            t_f = ['t_' obj.exec '.csv']; % csv type
            
            fprintf('main.m (expset): Reading presentation information -- %s.\n', t_f);
            fid = fopen([obj.path.bin filesep t_f]);
            
%             % Pulling header information
            head = cell([length(headnames) 2]);
            c = [];
%             k = zeros([length(headnames) max([head{:,1}])]);
%             dyn_str = [];
%             build_i = cell([length(headnames) 1]);
            for i = 1:length(headnames)
                head{i,1} = eval([head_f '.(headnames{i})']);
                head{i,2} = regexp(fgetl(fid),',','split');
                if ~isempty(c)
                    if c ~= length(head{i,2})
                        error(['main.m (expset): Inconsistent column length in file ' obj.path.bin filesep t_f '.']);
                    end
                else
                    c = length(head{i,2});
                end
%                 k(i,:) = 1:head{i,1}; % Index storage
%                 build_i{i} = char(double('k')+i); % Dynamic variable storage
%                 dyn_str = [dyn_str '.(headnames{' int2str(i) '})(k(' int2str(i) ',' build_i{i} '))']; % Dynamic structure building eval string
            end
            
            % Textscan (csv)
            s = [];
            for i = 1:c
                s = [s '%s'];
            end
            
            datin = textscan(fid,s,'Delimiter',',');
            dat = [datin{:}];
            
            % Building structure
            build = [];
            for i = 1:2
                for ii = 1:2
                    dat_i = intersect(find(strcmp(head{1,2},int2str(i))),find(strcmp(head{2,2},int2str(ii))));
                    build.seq(i).run(ii).pres = dat(:,dat_i-1);
                    build.seq(i).run(ii).t = dat(:,dat_i);
                end
            end
            
            % Building dynamic structure
%             %% Experimental code -- don't use with more header types (2 max)
%             try
%             temp1 = cell([mtimes(head{:,1}) 1]);
%             [temp1{:}] = deal(dyn_str); % Temporary repetition of dyn_str
%             k2 = zeros([mtimes(head{:,1}) size(k,1)]);
%             for i = size(k,1):-1:1 % Working backwards, fill in index
%                 if i-1 > 0
%                     k2(:,i) = repmat(k(i,:)',[length(k(i-1,:)) 1]);
%                 else
%                     k2(:,i) = sort(repmat(k(i,:)',[length(k(i,:)) 1])); % Sort if first index
%                 end
%             end
%             for i = 1:size(k,1) % Find and replace temp variables according to k2
%                 build_i_i = cellfun(@(y)(regexp(y,[build_i{i} ')'],'start')),temp1,'UniformOutput',false);
%                 for ii = 1:length(build_i_i)
%                     temp1{ii}(build_i_i{ii}) = int2str(k2(ii,i));
%                 end
%             end
%             build = [];
%             end_fill = 1;
%             while end_fill <= size(temp1,1) % Evaluate structure definition strings
%                 eval(['build' temp1{end_fill} '.pres = dat(:,' int2str(end_fill*2-1) ')']);
%                 eval(['build' temp1{end_fill} '.t = dat(:,' int2str(end_fill*2) ')']);
%                 end_fill = end_fill + 1;
%             end
%             catch ME
%                 throw(ME)
%             end
%             %%
            
            % Miscellaneous
            % Query user: subject info
            prompt={'Subject ID:', 'Sequence','Trigger','SkipRun'};
            name='Experiment Info';
            numlines=1;
            defaultanswer={datestr(now,30),'1','1','0'};
            s=inputdlg(prompt,name,numlines,defaultanswer);
            if isempty(s)
                error('User Cancelled.')
            end

            exp.dat = dat;
            exp.build = build;
            exp.subjinfo= s{1};
            if isnan(str2double(s{2}))
                error(['main.m (expset): Improper sequence value -- ' s{2}]);
            elseif ~any(str2double(s{2})==[1 2])
                error(['main.m (expset): Sequence value must be 1 or 2 -- ' s{2}]);
            else
                exp.seq = str2double(s{2});
            end
            
            if isnan(str2double(s{3}))
                error(['main.m (expset): Improper sequence value -- ' s{3}]);
            elseif ~any(str2double(s{3})==[0 1])
                error(['main.m (expset): Sequence value must be 0 or 1 -- ' s{3}]);
            else
                exp.trig = str2double(s{3});
            end
            
            if isnan(str2double(s{4}))
                error(['main.m (expset): Improper sequence value -- ' s{4}]);
            elseif ~any(str2double(s{3})==[0 1])
                error(['main.m (expset): Sequence value must be 0 or 1 -- ' s{4}]);
            else
                exp.skip = str2double(s{4});
            end
            
            exp.TR = 2;
            exp.iPAT = 0;
            exp.DisDaq = 4.75; % Verify with FDBK
            
            exp.movie_t = 30;
            exp.intro = 'Please wait for a moment....';
            exp.wait = 'Waiting for trigger....';
            
            if exp.skip
                exp.f_out = [exp.subjinfo '_' int2str(exp.seq) '_skipped.csv'];
            else
                exp.f_out = [exp.subjinfo '_' int2str(exp.seq) '.csv'];
            end

            fprintf('main.m (expset): Storing experimental properties.\n');
            obj.exp = exp;
            
        end

        function videoload(obj) % Requires open window in obj.monitor and content path
            [~,d] = system(['dir /b ' obj.path.content]);
            d = regexp(d(1:end-1),'\n','split');
            obj.mov = d;
            % Loading general content -- Video
            for i = 1:length(d)
                % Open movie file and retrieve basic info about movie:
                [movie(i).movieptr movie(i).movieduration movie(i).fps movie(i).imgw movie(i).imgh movie(i).count] = Screen('OpenMovie', obj.monitor.w, [obj.path.content filesep d{i}]);
                movie(i).name = d{i};
            end
            
            fprintf('main.m (videoload): Storing movie properties.\n');
            obj.movie = movie;
        end
        
        function addl(obj,src)
            obj.exp.lh = addlistener(src,'temp_t','PostSet',@(src,evt)tset(obj,src,evt));
            obj.exp.lh2 = addlistener(src,'abort','PostSet',@(src,evt)abortcycle(obj,src,evt));
        end
        
        function tset(obj,src,evt) % Corresponding to lh
            try
                obj.temp_t = evt.AffectedObject.temp_t;
            catch ME
                throw(ME);
            end
        end
        
        function abortcycle(obj,src,evt) % Corresponding to lh2
            try
                obj.abort = evt.AffectedObject.abort;
            catch ME
                throw(ME);
            end
        end
        
        function cycle(obj,run)
            % Initialize
            t0 = GetSecs;
            tic;
            i = 1;
            
            fid = fopen([obj.path.out filesep obj.exp.f_out],'a');
            fprintf(fid,'%s,%s,%s\r','Event','Scheduled','Reported');
            
            evt = obj.exp.build.seq(obj.exp.seq).run(run).pres{i};
            t = obj.exp.build.seq(obj.exp.seq).run(run).t{i};
            
            while ~obj.abort
                tnow = regexp(num2str(toc),'\d{1,3}','match','once'); % String conversion of time
                
                if strcmp(tnow,t) % As long as the integer matches
%                     disp(evt) % Temp event
%                     disp(t) % Temp declared start time
%                     disp(tnow) % Temp reported current time
                    if strcmp(evt,'end')
                        break;
                    elseif strcmp(evt,'fix')
                        notify(obj,'fix');
                    elseif ~isempty(regexp(evt,'.mov', 'once'))
                        obj.dat.movie = obj.movie(strcmp(evt,obj.mov));
                        notify(obj,'playback')
                    else
                        break;
                    end
%                     disp(obj.temp_t - t0) % Temp reported start time.
                    i = i + 1; % ***Essential to prevent racing notifications
                    
                    fprintf(fid,'%s,%s,%s\r',evt,t,num2str(obj.temp_t - t0));
                    
                    % Find next event and start time
                    evt = obj.exp.build.seq(obj.exp.seq).run(run).pres{i};
                    t = obj.exp.build.seq(obj.exp.seq).run(run).t{i};
                end
            end
            
            fclose(fid);
            Screen('Flip',obj.monitor.w); % Clear screen.
        end
        
    end
    
end

