% === DETECCIÓN DE ANOMALÍAS EN TRÁFICO IoT ===
clear; clc; close all;

archivo = '/Users/nerealopezcastillo/Desktop/TFG/datos/procesados/iot_traffic_validation.csv';

%% 1) LEER EL ARCHIVO COMO TEXTO Y ENCONTRAR LA CABECERA REAL
fid = fopen(archivo, 'r');
if fid == -1
    error('No se pudo abrir el archivo.');
end

lineas = {};
while ~feof(fid)
    lineas{end+1,1} = fgetl(fid); %#ok<SAGROW>
end
fclose(fid);

headerLine = [];
for i = 1:numel(lineas)
    linea = string(lineas{i});
    if contains(lower(linea), 'time') && contains(lower(linea), 'source') && contains(lower(linea), 'length')
        headerLine = i;
        break;
    end
end

if isempty(headerLine)
    error('No encontré la cabecera real del CSV. Abre el archivo y comprueba que exista una línea con Time, Source y Length.');
end

cabecera = string(lineas{headerLine});
disp("Cabecera detectada:")
disp(cabecera)

%% 2) DETECTAR DELIMITADOR
nComas = count(cabecera, ",");
nPuntoComa = count(cabecera, ";");
nTabs = count(cabecera, sprintf('\t'));

if nComas >= nPuntoComa && nComas >= nTabs
    delim = ",";
elseif nPuntoComa >= nComas && nPuntoComa >= nTabs
    delim = ";";
else
    delim = sprintf('\t');
end

disp("Delimitador detectado:")
disp(delim)

%% 3) IMPORTAR DESDE LA CABECERA CORRECTA
opts = detectImportOptions(archivo, ...
    'Delimiter', delim, ...
    'NumHeaderLines', headerLine-1, ...
    'VariableNamingRule', 'preserve');

data = readtable(archivo, opts);

disp("Primeras filas importadas:")
disp(data(1:min(5,height(data)), :))

disp("Nombres de columnas:")
disp(data.Properties.VariableNames)

%% 4) LOCALIZAR COLUMNAS IMPORTANTES
vars = string(data.Properties.VariableNames);
varsLow = lower(vars);

col_time = find(contains(varsLow, "time"), 1);
col_source = find(contains(varsLow, "source"), 1);
col_length = find(contains(varsLow, "length"), 1);

if isempty(col_time) || isempty(col_source) || isempty(col_length)
    error("No se encontraron las columnas Time / Source / Length después de importar.");
end

%% 5) EXTRAER Y LIMPIAR DATOS
tiempos = data{:, col_time};
ips_all = data{:, col_source};
bytes_all = data{:, col_length};

if iscell(tiempos) || isstring(tiempos) || ischar(tiempos)
    tiempos = str2double(string(tiempos));
end

if iscell(bytes_all) || isstring(bytes_all) || ischar(bytes_all)
    bytes_all = str2double(string(bytes_all));
end

if iscell(ips_all)
    ips_all = string(ips_all);
end

validos = ~isnan(tiempos) & ~isnan(bytes_all) & strlength(string(ips_all)) > 0;
tiempos = tiempos(validos);
ips_all = string(ips_all(validos));
bytes_all = bytes_all(validos);

disp("Tiempo mínimo:")
disp(min(tiempos))
disp("Tiempo máximo:")
disp(max(tiempos))
disp("Número de paquetes válidos:")
disp(numel(tiempos))

%% 6) ANÁLISIS POR VENTANAS
tam_ventana = 10; % prueba luego 5 y 20

t_inicio = floor(min(tiempos));
t_final = ceil(max(tiempos));

lista_entropia = [];
lista_dispersion = [];
centros = [];

for t = t_inicio:tam_ventana:t_final
    idx = tiempos >= t & tiempos < (t + tam_ventana);

    if sum(idx) == 0
        continue;
    end

    % Entropía de IP origen
    ips = ips_all(idx);
    [~,~,idx2] = unique(ips);
    cuentas = accumarray(idx2, 1);
    prob = cuentas / sum(cuentas);
    entropia = -sum(prob .* log2(prob));

    % Dispersión de tamaños
    bytes = bytes_all(idx);
    bytes = bytes(~isnan(bytes));

    if isempty(bytes) || mean(bytes) == 0
        continue;
    end

    dispersion = std(bytes) / mean(bytes);

    lista_entropia(end+1) = entropia; %#ok<SAGROW>
    lista_dispersion(end+1) = dispersion; %#ok<SAGROW>
    centros(end+1) = t + tam_ventana/2; %#ok<SAGROW>
end

disp("Entropías:")
disp(lista_entropia)

disp("Dispersiones:")
disp(lista_dispersion)

%% 7) DETECCIÓN DE ANOMALÍAS
mE = mean(lista_entropia);
mD = mean(lista_dispersion);
stdE = std(lista_entropia);
stdD = std(lista_dispersion);

anomalias = abs(lista_entropia - mE) > stdE | abs(lista_dispersion - mD) > stdD;

disp("Anomalías:")
disp(anomalias)

%% 8) GRÁFICOS
figure;
hold on;
scatter(lista_entropia(~anomalias), lista_dispersion(~anomalias), 80, 'b', 'filled');
scatter(lista_entropia(anomalias), lista_dispersion(anomalias), 80, 'r', 'filled');
xlabel('Entropía');
ylabel('Dispersión');
title(['Detección de anomalías (ventana = ', num2str(tam_ventana), ' s)']);
legend('Normal', 'Anómala', 'Location', 'best');
grid on;

figure;
plot(centros, lista_entropia, '-o', 'LineWidth', 1.5);
xlabel('Tiempo (s)');
ylabel('Entropía');
title('Entropía por ventana');
grid on;

figure;
plot(centros, lista_dispersion, '-o', 'LineWidth', 1.5);
xlabel('Tiempo (s)');
ylabel('Dispersión');
title('Dispersión por ventana');
grid on;