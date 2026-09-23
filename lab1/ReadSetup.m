function Params = ReadSetup(LogLanguage)
    Params = cell(0);

    FieldNames = { ...
        'Source', ...
        'Encoder', ...
        'Interleaver', ...
        'Mapper', ...
        'Sig', ...
        'Channel', ...
        'BER', ...
        'Common' ...
    };

    FileNames = cell(0);
    Listing = dir;
    for k = 1:length(Listing)
        if ~Listing(k).isdir
            if length(Listing(k).name) >= length('Setup.m')
                if strcmp(Listing(k).name(1:length('Setup')), ...
                        'Setup') && strcmp(Listing(k).name( ...
                        end-1:end), '.m')
                    FileNames{end+1} = Listing(k).name;
                end
            end
        end
    end

    for k = 1:length(FileNames)
        NumParams = length(Params);

        try
            fid = fopen(FileNames{k});
        catch
            if strcmp(LogLanguage, 'Russian')
                error(['Не удалось открыть файл настройки ', ...
                    '%s!\n'], FileNames{k});
            else
                error('Failed to open setup file %s!\n', FileNames{k});
            end
        end

        BufParams = [];

        tline = fgetl(fid);
        isFindEndOfParams = false;
        while ischar(tline)
            for n = 1:length(FieldNames)
                OldStr = [FieldNames{n}, '.'];
                NewStr = ['BufParams.', OldStr];
                tline = strrep(tline, OldStr, NewStr);
            end

            try
                eval(tline);
            catch
                if strcmp(LogLanguage, 'Russian')
                    error(['Не удалось выполнить ''%s'' ', ...
                        'в файле %s!\n'], tline, FileNames{k});
                else
                    error(['Failed to evaluate ''%s'' in ', ...
                        'file %s!\n'], tline, FileNames{k});
                end
            end

            isFindEndOfParams = contains(tline, '% End of Params');

            if isFindEndOfParams
                if ~isempty(BufParams)
                    Params{end+1} = BufParams;
                    BufParams = [];
                end
            end

            tline = fgetl(fid);
        end

        if ~isFindEndOfParams
            if ~isempty(BufParams)
                Params{end+1} = BufParams;
            end
        end

        fclose(fid);

        if strcmp(LogLanguage, 'Russian')
            fprintf(['%s Из файла %s считано %d наборов ', ...
                'параметров.\n'], datestr(now), FileNames{k}, ...
                length(Params) - NumParams);
        else
            fprintf(['%s %d parameter sets are parsed from ', ...
                'file %s.\n'], datestr(now), length(Params) - ...
                NumParams, FileNames{k});
        end
        fprintf('\n');
    end

    if isempty(Params)
        Params = cell(1);
        if strcmp(LogLanguage, 'Russian')
            fprintf(['%s Не найден ни один набор параметров, ', ...
                'поэтому будет выполнен один расчёт с ', ...
                'параметрами по умолчанию.\n'], datestr(now));
        else
            fprintf(['%s No parameters were found thus one ', ...
                'calculation with default parameters will be ', ...
                'performed.\n'], datestr(now));
        end
        fprintf('\n');
    end
end