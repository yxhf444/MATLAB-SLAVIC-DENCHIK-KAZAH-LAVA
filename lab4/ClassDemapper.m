classdef ClassDemapper < handle
    methods
        function llr = StepRx(obj, symbols, modType, N0)
            switch upper(modType)
                case 'QPSK'
                    N0_eff = max(N0, 1e-6);
                    a = sqrt(2);
                    llrI = 2*a*real(symbols(:).') / N0_eff;
                    llrQ = 2*a*imag(symbols(:).') / N0_eff;
                    llr = zeros(1, 2*numel(symbols));
                    llr(1:2:end) = llrI;
                    llr(2:2:end) = llrQ;
                otherwise
                    error('ClassDemapper: unsupported modulation "%s"', modType);
            end
        end
    end
end