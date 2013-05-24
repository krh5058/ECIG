classdef pres < handle
    % pres.m class for ecig.m
    % See dated ReadMe file
    
    properties
        movie
        txt
        fix_color
        misc
        keys
        lh
    end
    
    properties (SetObservable)
        temp_t
        abort = 0;
    end
    
    methods
        function obj = pres(src)
                        
            % Function handles
            fprintf('pres.m (pres): Defining presentation function handles...\n');
            misc.fix1 = @(monitor,color)(Screen('DrawLine',monitor.w,color,monitor.center_W-20,monitor.center_H,monitor.center_W+20,monitor.center_H,7));
            misc.fix2 = @(monitor,color)(Screen('DrawLine',monitor.w,color,monitor.center_W,monitor.center_H-20,monitor.center_W,monitor.center_H+20,7));
            misc.text = @(monitor,txt)(DrawFormattedText(monitor.w,txt,'center','center',monitor.white));
            
            % Keys
            fprintf('pres.m (pres): Defining key press identifiers...\n');
            KbName('UnifyKeyNames');
            keys.esckey = KbName('Escape');
            keys.spacekey = KbName('SPACE');
            keys.tkey = KbName('t');
            
            % Listeners
            fprintf('pres.m (pres): Defining listener function handles...\n');
            lh.lh1 = addlistener(src,'fix',@(src,evt)dispfix(obj,src,evt));
            lh.lh2 = addlistener(src,'playback',@(src,evt)videoplayback(obj,src,evt));
            lh.lh3 = addlistener(src,'txt',@(src,evt)disptxt(obj,src,evt));
            lh.lh4 = addlistener(src,'dat','PostSet',@(src,evt)propset(obj,src,evt));
            
            fprintf('pres.m (pres): Storing object properties...\n');
            obj.misc = misc;
            obj.keys = keys;
            obj.lh = lh;
            
            fprintf('pres.m (pres): Success!\n');
        end
        
        function dispfix(obj,src,evt) % Corresponding to lh1
            obj.misc.fix1(src.monitor,obj.fix_color);
            obj.misc.fix2(src.monitor,obj.fix_color);
            obj.temp_t = Screen('Flip',src.monitor.w);
        end
        
        function videoplayback(obj,src,evt) % Corresponding to lh2
            % Child protection
            AssertOpenGL;
            
            % Seek to start of movie (timeindex 0):
            Screen('SetMovieTimeIndex', obj.movie.movieptr, 0, 0);
            
            % Start playback of movie. This will start
            % the realtime playback clock and playback of audio tracks, if any.
            % Play 'movie', at a playbackrate = 1, with endless loop=1 and
            % 1.0 == 100% audio volume.
            Screen('PlayMovie', obj.movie.movieptr, 1, 0, 0);
            
            i = 0;
            
            mov_start = GetSecs; % Start time
            obj.temp_t = mov_start;
            
            while i < obj.movie.count
                try
                    
                    % Check for time (and some buffer)
                    if GetSecs-mov_start >= (src.exp.movie_t - .2)
                        break;
                    end
                    
                    [keyIsDown,secs,keyCode]=KbCheck; %#ok<ASGLU>
                    if (keyIsDown==1 && keyCode(obj.keys.esckey))
                        obj.abort = 1;
                        break;
                    end;
                    
                    i=i+1; % Add iteration
                    
                    % Return next frame in movie, in sync with current playback
                    % time and sound.
                    % tex either the texture handle or zero if no new frame is
                    % ready yet. pts = Presentation timestamp in seconds.
                    [tex] = Screen('GetMovieImage', src.monitor.w, obj.movie.movieptr, 1, [], [], 1);
                    
                    if tex==-1 % Break if no texture loaded
                        break;
                    end
                    
                    % Draw the new texture immediately to screen:
                    Screen('DrawTexture', src.monitor.w, tex);
                    
                    Screen('Flip', src.monitor.w); % Process subsequent flips according to timeindex, but do not have MatLab wait for execution (timestamps are invalid)
                    % Release texture:
                    Screen('Close', tex);
                    
                catch ME
                    disp(ME.message)
                end
                
            end % End while(1)
            
%             mov_end = GetSecs-mov_start;
            
            %movie.pts = pts;
            
            % % Done. Stop playback:
            % Screen('PlayMovie', movieptr, 0);
            
            % Close movie object:
%             Screen('CloseMovie', obj.movie.movieptr);
            Screen('Flip',src.monitor.w); % Clear screen
        end
        
        function disptxt(obj,src,evt) % Corresponding to lh3
            obj.misc.text(src.monitor,obj.txt);
            obj.temp_t = Screen('Flip',src.monitor.w);
        end
        
        function propset(obj,src,evt) % Corresponding to lh4
            try
                f = fieldnames(evt.AffectedObject.dat);
                for i = 1:length(f)
                    obj.(f{i}) = evt.AffectedObject.dat.(f{i});
                end
            catch ME
                throw(ME);
            end
        end
    end
    
end

