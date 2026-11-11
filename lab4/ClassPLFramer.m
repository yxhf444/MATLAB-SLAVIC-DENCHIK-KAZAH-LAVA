classdef ClassPLFramer < handle
    properties (SetAccess = private)
        SlotLen
        PilotLen
        PilotPeriod
        PilotSymbol
    end

    methods
        function obj = ClassPLFramer()
            obj.SlotLen     = 90;
            obj.PilotLen    = 36;
            obj.PilotPeriod = 16;
            obj.PilotSymbol = (1 + 1j) / sqrt(2);
        end

        function [outSymbols, pilotFlags, numSlots] = insertPilots(obj, xFecFrameSymbols, hasPilots)
            L = length(xFecFrameSymbols);
            numSlots = floor(L / obj.SlotLen);
            tail = L - numSlots * obj.SlotLen;

            outSymbols = [];
            pilotFlags = [];

            if ~hasPilots
                outSymbols = xFecFrameSymbols;
                pilotFlags = zeros(1, L);
                return
            end

            for s = 1:numSlots
                idx = (s-1)*obj.SlotLen + 1 : s*obj.SlotLen;
                outSymbols = [outSymbols, xFecFrameSymbols(idx)];
                pilotFlags = [pilotFlags, zeros(1, obj.SlotLen)];

                if mod(s, obj.PilotPeriod) == 0 && s < numSlots
                    outSymbols = [outSymbols, obj.PilotSymbol * ones(1, obj.PilotLen)];
                    pilotFlags = [pilotFlags, ones(1, obj.PilotLen)];
                end
            end

            if tail > 0
                idx = numSlots*obj.SlotLen + 1 : L;
                outSymbols = [outSymbols, xFecFrameSymbols(idx)];
                pilotFlags = [pilotFlags, zeros(1, tail)];
            end
        end

        function plFrame = assemblePLFrame(obj, plHeaderSym, xFecPilots)
            scr = ClassScrambler();
            scrambledTail = scr.scramblePL(xFecPilots, 0, 0);
            plFrame = [plHeaderSym, scrambledTail];
        end

        function out = extractPilots(obj, symbols, hasPilots)
            if ~hasPilots
                out = symbols;
                return
            end
            out = []; idx = 1; L = length(symbols); slotCnt = 0;
            while idx <= L
                if idx + obj.SlotLen - 1 > L
                    out = [out, symbols(idx:end)]; break;
                end
                out = [out, symbols(idx : idx + obj.SlotLen - 1)];
                idx = idx + obj.SlotLen; slotCnt = slotCnt + 1;
                if mod(slotCnt, obj.PilotPeriod) == 0 && idx + obj.PilotLen - 1 <= L
                    idx = idx + obj.PilotLen;
                end
            end
        end
    end
end