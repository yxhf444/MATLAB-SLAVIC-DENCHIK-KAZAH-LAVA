classdef ClassReceiver < handle
    properties
        Beta = 0.35;
        Span = 10;
        Sps  = 4;
    end
    
    methods
                function [recoveredBits, isSuccess, info] = process(obj, plFrameIn, MODCOD, hasPilots, N_ldpc, K_bch)
            recoveredBits = []; isSuccess = false; info = struct();
            
            %% 1. Идеальная синхронизация
            rxSym = plFrameIn; 
            
            %% 1.5. Поиск правильного сдвига и фазы по PLHEADER
            hdr = ClassPLHeader();
            ref_plh = hdr.Step(); 
            
            best_shift = 1;
            best_metric = -inf;
            
            for shift = 1:6
                if shift + 89 > length(rxSym), break; end
                test_sym = rxSym(shift : shift+89);
                metric = abs(sum(test_sym .* conj(ref_plh)));
                if metric > best_metric
                    best_metric = metric;
                    best_shift = shift;
                end
            end
            
            rxSym = rxSym(best_shift : end);
            
            %% 2. Декодирование PLHEADER
            [modcodRx, typeRx] = hdr.decode(rxSym(1:90));
            
            %% 3. PL-дескремблирование
            scr = ClassScrambler();
            % Берем символы после PLHEADER и дескремблируем
            xFec = scr.descramblePL(rxSym(91:end));
            
            %% 4. Удаление пилотов
            plf = ClassPLFramer();
            xFec = plf.extractPilots(xFec, hasPilots);
            
            if length(xFec) > N_ldpc/2
                xFec = xFec(1 : N_ldpc/2);
            end
            
            %% 5. Деммаппинг
            dem = ClassDemapper();
            llr = dem.StepRx(xFec, 'QPSK', 1e-6); % <--- Без best_invert!
            
            %% 6. Деперемежение
            il = ClassBitInterleaver();
            llr = il.StepRx(llr);
            
            %% 7. LDPC-декодирование
            H = dvbs2ldpc(1/2);
            if exist('ldpcDecoderConfig', 'file') || exist('ldpcDecoderConfig', 'builtin')
                cfg = ldpcDecoderConfig(H);
                [fecBits, iter] = ldpcDecode(llr(:), cfg, 50);
                fecBits = fecBits(:).';
            else
                ldpcDec = comm.LDPCDecoder(H, 'MaximumIterationCount', 50);
                fecBits = step(ldpcDec, llr(:)).';
                iter = 50;
            end
            info.ldpcIters = iter;
            
            %% 8. BCH-декодирование
            enc = ClassEncoder();
            [bbFrameScr, bchOk] = enc.decodeBCH(fecBits, K_bch);
            info.bchOk = bchOk;
            if ~bchOk
                warning('BCH: синдром ненулевой. Возможно, ошибки в LDPC. Продолжаем...');
                % Не делаем return! Пусть попробует распарсить, что есть.
            end
            
            %% 9. BB-дескремблирование
            bbFrame = scr.scrambleBB(bbFrameScr); % XOR обратим
            
            %% 10. Разбор BBFRAME
            h = ClassHeader();
            [recoveredBits, isSuccess, info.numPackets] = h.parseBBFrame(bbFrame);
            info.numPackets = 0;
        end
    end
end