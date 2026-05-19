% === CARGAR DATOS ===
data = readtable('/Users/nerealopezcastillo/Desktop/TFG/datos/procesados/Trafico.csv'); 

% === ENTROPÍA DE IP ORIGEN ===
ips = data.Source;   % columna con las IP origen
[unicas, ~, idx] = unique(ips);
cuentas = histcounts(idx, length(unicas));
prob = cuentas / sum(cuentas);
entropia = -sum(prob .* log2(prob));
fprintf('Entropía de IPs origen: %.3f\n', entropia);

% === DISPERSIÓN DE BYTES ===
bytes = data.Length;   % columna con tamaño de cada paquete
media = mean(bytes);
desv = std(bytes);
dispersion = 0.01 * asin( media / sqrt(desv^2 + media^2) );
fprintf('Dispersión de Bytes: %.3f\n', dispersion);

% === GRAFICAR PUNTO ===
figure;
plot(entropia, dispersion, 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');
xlabel('Entropía'); ylabel('Dispersión');
title('Comportamiento del tráfico');
grid on;
