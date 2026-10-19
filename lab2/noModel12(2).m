clear; clc;

%% ================== ПАРАМЕТРЫ СИСТЕМЫ ==================
R_ldpc = 1/2;
N_ldpc = 64800;
K_bch  = 32208;

MODCOD   = 4;        % QPSK 1/2 (как в ClassPLFramer)
MOD_TYPE = 'QPSK';

MPEG_packet_len_bytes = 188;
MPEG_packet_len_bits  = MPEG_packet_len_bytes * 8;   % 1504
Data_field_len_bits   = 1496;

Max_DFL     = K_bch - 80;
num_packets = floor(Max_DFL / MPEG_packet_len_bits);
DFL         = num_packets * MPEG_packet_len_bits;

fprintf('Пакетов MPEG-TS: %d, DFL = %d бит\n', num_packets, DFL);

%% ================== 1. ИСТОЧНИК ==================
src = ClassSource();
mpegBits = src.generateData();
fprintf('Сгенерировано бит от источника: %d\n', length(mpegBits));

%% ================== 2. АДАПТАЦИЯ + CRC-8 ==================
enc = ClassEncoder();
dataField = enc.adaptPacketsAndCRC(mpegBits);
fprintf('Длина dataField после CRC: %d (ожидалось %d)\n', ...
        length(dataField), DFL);

%% ================== 3. BBHEADER + PADDING ==================
hdr = ClassHeader();
bbFrame = hdr.createBBFrame(dataField, K_bch);
fprintf('Длина BBFRAME: %d (ожидалось %d)\n', length(bbFrame), K_bch);

%% ================== 4. BB SCRAMBLING ==================
scr = ClassScrambler();
scrambledFrame = scr.scrambleBB(bbFrame);
fprintf('BB-скремблирование выполнено, длина: %d\n', length(scrambledFrame));

%% ================== 5. BCH + LDPC (ЗАГЛУШКА ДЛЯ ДЛИНЫ) ==================
% В реальной системе здесь считается BCH и LDPC.
% Для проверки модулятора и PL-уровня нам критически важна ТОЛЬКО длина кадра.
% Поэтому мы просто добиваем кадр нулями до 64800 бит.

bchParity = zeros(1, 192); % 32400 - 32208 = 192 бита BCH
ldpcParity = zeros(1, N_ldpc - K_bch - 192); % Остаток до 64800 бит

fecFrame = [scrambledFrame, bchParity, ldpcParity];
fprintf('Длина FECFRAME (заглушка): %d (ожидалось %d)\n', length(fecFrame), N_ldpc);

%% ================== 6. ПЕРЕМЕЖЕНИЕ ==================
il = ClassInterleaver();
interleavedBits = il.interleave(fecFrame, MOD_TYPE, N_ldpc);
fprintf('Перемежение (%s) выполнено, длина: %d\n', MOD_TYPE, length(interleavedBits));

%% ================== 7. МОДУЛЯЦИЯ QPSK ==================
% Отображение Gray для QPSK:
% 00 -> (1+j)/√2, 01 -> (-1+j)/√2, 11 -> (-1-j)/√2, 10 -> (1-j)/√2
bitsI = interleavedBits(1:2:end);
bitsQ = interleavedBits(2:2:end);

% Нормировка 1/sqrt(2)
symI = (1 - 2*bitsI) / sqrt(2);
symQ = (1 - 2*bitsQ) / sqrt(2);
xFecFrameSymbols = symI + 1j * symQ;

fprintf('Символов QPSK в XFECFRAME: %d\n', length(xFecFrameSymbols));

%% ================== 8. PL SCRAMBLING ==================
scrambledSymbols = scr.scramblePL(xFecFrameSymbols);
fprintf('PL-скремблирование (Gold) выполнено, длина: %d\n', ...
        length(scrambledSymbols));

%% ================== 9. PL HEADER + ВСТАВКА ПИЛОТОВ ==================
plf = ClassPLFramer();

% PLHEADER (SOF + PLS), модуляция pi/2 BPSK -> 90 символов
plHeaderSym = plf.createPLHeader(MODCOD);
fprintf('Длина PLHEADER: %d символов\n', length(plHeaderSym));

% Вставка пилотов в XFECFRAME (P=36 каждые 16 слотов по 90)
[xFecPilots, pilotFlags] = plf.insertPilots(scrambledSymbols);
fprintf('XFECFRAME после вставки пилотов: %d символов (пилотов: %d)\n', ...
        length(xFecPilots), sum(pilotFlags));

%% ================== 10. ИТОГОВЫЙ КАДР ==================
% PLFRAME = PLHEADER + XFECFRAME (с пилотами)
plFrame = [plHeaderSym, xFecPilots];
fprintf('Итоговый PLFRAME: %d символов\n', length(plFrame));