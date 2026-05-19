% === PARÁMETRO: tamaño de ventana en segundos ===
tam_ventana = 5; 

% Obtener tiempos
tiempos = data.Time;
t_inicio = min(tiempos);
t_final = max(tiempos);

% Inicializar vectores
lista_entropia = [];
lista_dispersion = [];

% Recorrer ventanas
for t = t_inicio:tam_ventana:t_final
    % Filtrar paquetes dentro de esta ventana
    idx = tiempos >= t & tiempos < t + tam_ventana;
    subdata = data(idx,:);
    
    if isempty(subdata)
        continue; % si no hay paquetes, saltar
    end
    
    % --- Entropía ---
    ips = subdata.Source;
    [unicas, ~, idx2] = unique(ips);
    cuentas = histcounts(idx2, length(unicas));
    prob = cuentas / sum(cuentas);
    entropia = -sum(prob .* log2(prob));
    
    % --- Dispersión ---
    bytes = subdata.Length;
    media = mean(bytes);
    desv = std(bytes);
    dispersion = 0.01 * asin( media / sqrt(desv^2 + media^2) );
    
    % Guardar
    lista_entropia(end+1) = entropia;
    lista_dispersion(end+1) = dispersion;
end

% === Graficar todos los puntos ===
figure;
plot(lista_entropia, lista_dispersion, 'bo', 'MarkerSize', 6, 'MarkerFaceColor','b');
xlabel('Entropía');
ylabel('Dispersión');
title('Evolución del tráfico por ventanas');
grid on;
