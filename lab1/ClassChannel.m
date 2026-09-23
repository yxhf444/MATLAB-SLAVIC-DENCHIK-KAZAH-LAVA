classdef ClassChannel < handle
    properties (SetAccess = private)
        isTransparent;
        LogLanguage;
    end
    properties (SetAccess = private)
        Ps;
        Pb;
        Pbd;
    end
    methods
        function obj = ClassChannel(Params, Objs, LogLanguage)
            Channel = Params.Channel;
            obj.isTransparent = Channel.isTransparent;
            obj.LogLanguage = LogLanguage;

            Const = Objs.Mapper.Constellation;
            obj.Ps = mean((abs(Const)).^2);
            obj.Pb = obj.Ps / Objs.Mapper.log2M;
            obj.Pbd = obj.Pb;
        end
        function [OutData, InstChannelParams] = Step(obj, InData, h2dB)
            if obj.isTransparent
                OutData = InData;
                InstChannelParams.Variance = 1;
                return
            end
            Sigma = sqrt(obj.Pbd * 10^(-h2dB/10) / 2);
            InstChannelParams.Variance = 2*Sigma^2;
            Noise = randn(length(InData), 2) * [1; 1i] * Sigma;
            OutData = InData + Noise;
        end
    end
end