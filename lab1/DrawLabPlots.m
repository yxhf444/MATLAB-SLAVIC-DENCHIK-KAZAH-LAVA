function DrawLabPlots(AllResults)
    N = length(AllResults);
    beta_values = cellfun(@(r) r.beta, AllResults);

    %qpsk созвездие на выходе маппера
    R1 = AllResults{1};
    figure;
    plot(real(R1.modSymbs), imag(R1.modSymbs), 'o', 'MarkerSize', 8, ...
        'MarkerFaceColor', 'b');
    grid on;
    axis equal;
    xlim([-1.5 1.5]);
    ylim([-1.5 1.5]);
    title('qpsk созвездие на выходе маппера');
    xlabel('Re');
    ylabel('Im');

    % RRC сигнал, subplot по beta
    figure;
    for i = 1:N
        R = AllResults{i};
        subplot(N, 1, i);
        plot((0:300-1)/R.Fs, real(R.sig(1:300)));
        grid on;
        xlabel('t');
        ylabel('Re\{s(t)\}');
        title(['RRC, \beta = ', num2str(R.beta)]);
    end

    % Периодограмма (норм.), subplot по beta
    figure;
    for i = 1:N
        R = AllResults{i};
        subplot(N, 1, i);
        S = fftshift(fft(R.sig, R.Nfft));
        pslgod = (abs(S).^2) / (R.Fs * R.Nfft);
        f = (-R.Nfft/2 : R.Nfft/2 - 1) * (R.Fs / R.Nfft);
        plot(f, 10*log10(pslgod / max(pslgod) + eps));
        grid on;
        xlim([-2 2]);
        ylim([-60 5]);
        xlabel('f, Гц');
        ylabel('Норм. PSD, dB');
        title(['Периодограмма (норм.), \beta = ', num2str(R.beta)]);
    end

    % Энергетический спектр Велч для разных beta
    window = hamming(1024);
    noverlap = 512;
    colors = {'b', 'r', 'g'};
    figure;
    hold on;
    for i = 1:N
        R = AllResults{i};
        [pxx, fw] = pwelch(R.sig, window, noverlap, R.Nfft, R.Fs, 'centered');
        Gw = 10*log10(pxx + eps);
        plot(fw, Gw, 'Color', colors{i}, 'LineWidth', 1.2);
    end
    hold off;
    grid on;
    xlim([-2 2]);
    xlabel('Частота, Гц');
    ylabel('PSD, дБ');
    title('Энергетический спектр Велч для разных \beta');
    legend(arrayfun(@(b) sprintf('\\beta = %.2f', b), beta_values, ...
           'UniformOutput', false));

    %Сравнение спектров, subplot по beta
    figure;
    for i = 1:N
        R = AllResults{i};
        subplot(N, 1, i);
        f_compare = (-R.Nfft/2 : R.Nfft/2 - 1) * (R.Fs / R.Nfft);
        S = fftshift(fft(R.sig, R.Nfft));
        PSD = abs(S).^2;
        Rf = fftshift(fft(R.rrc, R.Nfft));
        RPSD = abs(Rf).^2;
        plot(f_compare, 10*log10(PSD / max(PSD) + eps), 'b');
        hold on;
        plot(f_compare, 10*log10(RPSD / max(RPSD) + eps), 'r', 'LineWidth', 1.5);
        hold off;
        grid on;
        xlim([-2 2]);
        ylim([-50 5]);
        xlabel('f, Гц');
        ylabel('Норм. PSD, dB');
        title(['Сравнение спектров, \beta = ', num2str(R.beta)]);
        legend('QPSK + RRC (Сигнал)', 'RRC импульс (Фильтр)');
    end
    
    % Таблица PAPR / спектральная эффективность
    PAPR_rrc  = zeros(1, N);
    PAPR_env  = zeros(1, N);
    SpecEff   = zeros(1, N);
    CCDF_level = 1e-4;

    for i = 1:N
        R = AllResults{i};

        % PAPR RRC импульса
        a = R.rrc;
        PAPR_rrc(i) = 10*log10( max(abs(a).^2) / mean(abs(a).^2) );

        % PAPR комплексной огибающей по CCDF = 1e-4
        P_inst = abs(R.sig).^2;
        papr_db_inst = 10*log10(P_inst / mean(P_inst));
        sorted_papr = sort(papr_db_inst, 'descend');
        ccdf = (1:length(sorted_papr))' / length(sorted_papr);
        idx = find(ccdf <= CCDF_level, 1, 'first');
        if isempty(idx)
            PAPR_env(i) = sorted_papr(end);
        else
            PAPR_env(i) = sorted_papr(idx);
        end

        % Спектральная эффективность
        SpecEff(i) = 2*R.k / (1 + R.beta);
    end

    fprintf('\n beta | PAPR RRC, дБ | PAPR огиб., дБ | Спектр. эфф., (бит/с)/Гц\n');
    fprintf('------+--------------+----------------+--------------------------\n');
    for i = 1:N
        fprintf(' %4.2f | %12.3f | %14.3f | %24.3f\n', ...
            beta_values(i), PAPR_rrc(i), PAPR_env(i), SpecEff(i));
    end

    % CCDF пик-фактора комплексной огибающей
    figure;
    for i = 1:N
        R = AllResults{i};
        P_inst = abs(R.sig).^2;
        papr_db_inst = 10*log10(P_inst / mean(P_inst));
        sorted_papr = sort(papr_db_inst, 'descend');
        ccdf = (1:length(sorted_papr))' / length(sorted_papr);
        semilogy(sorted_papr, ccdf, 'LineWidth', 1.2);
        hold on;
    end
    hold off;
    grid on;
    xlabel('PAPR, дБ');
    ylabel('CCDF');
    title('CCDF пик-фактора комплексной огибающей');
    legend(arrayfun(@(b) sprintf('\\beta = %.2f', b), beta_values, ...
        'UniformOutput', false));
    xlim([0 15]);
    ylim([1e-5 1]);

    % Задача 4. Помехоустойчивость QPSK с RRC
    R1 = AllResults{1};
    figure;
    semilogy(R1.EbN0_dB, R1.BER_theor, 'k-', 'LineWidth', 1.5);
    hold on;
    markers = {'o','s','^'};
    for i = 1:N
        R = AllResults{i};
        semilogy(R.EbN0_dB, R.BER_sim, ['-' markers{i}], 'LineWidth', 1.2);
    end
    hold off;
    grid on;
    xlabel('E_b/N_0, дБ');
    ylabel('BER');
    title('Помехоустойчивость приема QPSK с RRC в канале с АБГШ');
    legend([{'Теория (без МСИ)'}, arrayfun(@(b) sprintf('\\beta = %.2f', b), ...
        beta_values, 'UniformOutput', false)]);
    ylim([1e-6 1]);

    %Задача 5. Созвездие на выходе СФ, tiledlayout по beta
    EbN0_demo_dB = 8;
    EbN0_demo = 10^(EbN0_demo_dB/10);
    figure('Position', [80 80 1500 520], 'Color', 'w');
    t = tiledlayout(1, N, 'TileSpacing', 'compact', 'Padding', 'compact');
    for i = 1:N
        R = AllResults{i};
        Ps = mean(abs(R.sig).^2);
        Rb = R.k / R.T;
        N0 = Ps / (EbN0_demo * Rb);
        sigma2 = N0 * R.Fs / 2;
        noise = sqrt(sigma2) * (randn(size(R.sig)) + 1j*randn(size(R.sig)));
        r = R.sig + noise;
        y = conv(r, R.rrc, 'full');
        Lr = length(R.rrc);
        delay = (Lr - 1);
        y = y(delay+1 : end);
        y_sym = y(1 : R.sps : end);
        y_sym = y_sym(1:length(R.modSymbs));
        nexttile;
        plot(real(y_sym), imag(y_sym), '.', 'MarkerSize', 4, ...
            'Color', [0.15 0.45 0.85 0.35]);
        hold on;
        plot(real(R.modSymbs), imag(R.modSymbs), 'ko', ...
            'MarkerSize', 9, 'MarkerFaceColor', 'k', 'LineWidth', 1.0);
        hold off;
        grid on;
        box on;
        axis equal;
        xlim([-1.6 1.6]);
        ylim([-1.6 1.6]);
        xlabel('Re', 'FontSize', 11);
        ylabel('Im', 'FontSize', 11);
        title(sprintf('\\beta = %.2f', R.beta), 'FontSize', 12);
    end
    title(t, sprintf(['Задача 5. Созвездие на выходе согласованного ' ...
        'фильтра,  E_b/N_0 = %d дБ'], EbN0_demo_dB), ...
        'FontSize', 14, 'FontWeight', 'bold');
    lg = legend({'Принятые символы', 'Идеальные символы'}, ...
        'Orientation', 'horizontal', 'FontSize', 10);
    lg.Layout.Tile = 'south';

    % Задача 6. Помехоустойчивость QPSK с RRC 
    figure;
    semilogy(R1.EbN0_dB, R1.BER_theor, 'k-', 'LineWidth', 2);
    hold on;
    for i = 1:N
        R = AllResults{i};
        semilogy(R.EbN0_dB, R.BER_sim, ['-' markers{i}], 'LineWidth', 1.5);
    end
    hold off;
    grid on;
    xlabel('E_b/N_0, дБ');
    ylabel('BER');
    title('Задача 6. Помехоустойчивость приема QPSK с RRC в канале с АБГШ');
    legend([{'Теория (без МСИ)'}, arrayfun(@(b) sprintf('\\beta = %.2f', b), ...
        beta_values, 'UniformOutput', false)]);
    ylim([1e-6 1]);

    % задача 6
    fprintf('\nЗадача 6. Вероятность битовой ошибки (BER)\n');
    fprintf('Eb/N0, дБ |');
    for i = 1:N
        fprintf(' beta=%.2f |', beta_values(i));
    end
    fprintf(' Теория   |\n');
    fprintf('----------+');
    for i = 1:N
        fprintf('-----------+');
    end
    fprintf('----------+\n');
    for j = 1:length(R1.EbN0_dB)
        fprintf('%9.1f |', R1.EbN0_dB(j));
        for i = 1:N
            R = AllResults{i};
            fprintf(' %9.2e |', R.BER_sim(j));
        end
        fprintf(' %8.2e |\n', R1.BER_theor(j));
    end
end