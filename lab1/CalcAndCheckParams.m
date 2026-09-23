function Params = CalcAndCheckParams(inParams, LogLanguage)
    Params = inParams;

    if Params.Encoder.isTransparent
        Params.Mapper.DecisionMethod = 'Hard decision';
    end

    if Params.Encoder.isTransparent
        if mod(Params.Source.NumBitsPerFrame, ...
                log2(Params.Mapper.ModulationOrder)) > 0
            if strcmp(LogLanguage, 'Russian')
                error(['В модулятор поступает число бит не кратное ', ...
                    'log2(M).']);
            else
                error(['The number of bits at the input of the ', ...
                    'mapper is not multiple of log2(M).']);
            end
        end
    end

    if ~Params.Sig.isTransparent
        if Params.Sig.SPS < 1 || mod(Params.Sig.SPS, 1) ~= 0
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Sig.SPS');
            else
                error('Invalid value Sig.SPS');
            end
        end
        if Params.Sig.Span < 1 || mod(Params.Sig.Span, 1) ~= 0
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Sig.Span');
            else
                error('Invalid value Sig.Span');
            end
        end
        if Params.Sig.Rolloff < 0 || Params.Sig.Rolloff > 1
            if strcmp(LogLanguage, 'Russian')
                error('Недопустимое значение Sig.Rolloff');
            else
                error('Invalid value Sig.Rolloff');
            end
        end
    end
end