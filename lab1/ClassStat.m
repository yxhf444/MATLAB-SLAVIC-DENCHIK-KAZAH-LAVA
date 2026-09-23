classdef ClassStat < handle
    properties (SetAccess = private)
        NumTrBits;
        NumTrFrames;
        NumErBits;
        NumErFrames;
        LogLanguage;
    end
    methods
        function obj = ClassStat(LogLanguage)
            obj.NumTrBits = 0;
            obj.NumTrFrames = 0;
            obj.NumErBits = 0;
            obj.NumErFrames = 0;
            obj.LogLanguage = LogLanguage;
        end
        function Step(obj, Frame)
            obj.NumTrBits = obj.NumTrBits + length(Frame.TxData);
            obj.NumTrFrames = obj.NumTrFrames + 1;
            Buf = sum(Frame.TxData ~= Frame.RxData);
            obj.NumErBits = obj.NumErBits + Buf;
            obj.NumErFrames = obj.NumErFrames + sign(Buf);
        end
        function Reset(obj)
            obj.NumTrBits = 0;
            obj.NumTrFrames = 0;
            obj.NumErBits = 0;
            obj.NumErFrames = 0;
        end
    end
end