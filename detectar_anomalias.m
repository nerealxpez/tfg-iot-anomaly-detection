% === DETECCIÓN DE ANOMALÍAS EN TRÁFICO ===
% Lee los datos desde el CSV exportado en Wireshark
data = readtable('/Users/nerealopezcastillo/Desktop/TFG/datos/procesados/iot_traffic_validation_clean.csv');

tam_ventana = 20; % segundos

% Tiempo
tiempos = data{:,2};
if iscell(tiempos) || isstring(tiempos)
    tiempos = str2double(string(tiempos));
end 

t_inicio = min(tiempos);
t_final = max(tiempos);

lista_entropia = [];
lista_dispersion = [];

for t = t_inicio:tam_ventana:t_final
    idx = tiempos >= t & tiempos < t + tam_ventana;
    subdata = data(idx,:);
    
    if isempty(subdata), continue; end
    
    % Entropía
    ips = subdata{:,3};
    [unicas, ~, idx2] = unique(ips);
    cuentas = accumarray(idx2,1);
    prob = cuentas / sum(cuentas);
    entropia = -sum(prob .* log2(prob));
    
    % Dispersión
    bytes = subdata{:,6};
if iscell(bytes) || isstring(bytes)
    bytes = str2double(string(bytes));
end

bytes = bytes(~isnan(bytes));

if isempty(bytes) || mean(bytes) == 0
    continue;
end

dispersion = std(bytes) / mean(bytes); % convertir tamaño a número
    
    
    lista_entropia(end+1) = entropia;
    lista_dispersion(end+1) = dispersion;
end

% Comprobación
disp('Entropías:')
disp(lista_entropia)

disp('Dispersiones:')
disp(lista_dispersion)



% === DETECTAR ANOMALÍAS ===
mE = mean(lista_entropia);
mD = mean(lista_dispersion);
stdE = std(lista_entropia);
stdD = std(lista_dispersion);

% Umbral menos estricto (1 desviación estándar en lugar de 2)
anomalias = abs(lista_entropia - mE) > stdE | abs(lista_dispersion - mD) > stdD;

% === GRAFICAR ===
figure;
hold on;
plot(lista_entropia(~anomalias), lista_dispersion(~anomalias), 'bo', 'MarkerFaceColor','b', 'MarkerSize',8); % normales
plot(lista_entropia(anomalias), lista_dispersion(anomalias), 'ro', 'MarkerFaceColor','r', 'MarkerSize',8);   % anómalos
xlabel('Entropía');
ylabel('Dispersión');
title('Detección de anomalías');
grid on;

disp(lista_entropia)
disp(lista_dispersion)
disp(anomalias)
