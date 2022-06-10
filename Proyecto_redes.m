clear
close all;
clc;

%Variables del programa
I=7;
K=15;
ranura_sleep=18;
contador_buffer=0;
DIFS=10e-3;
SIFS=5e-3;
durRTS=11e-3;
durCTS=11e-3;
durACK=11e-3;
durDATA=43e-3;
dur_miniranura=1e-3;
t_sim=0;
W=16;
N=5;
tasa_paquetes=0.03;
T=durDATA+durRTS+durCTS+DIFS+durACK+(dur_miniranura*W)+3*SIFS;
Tc=T*(ranura_sleep+2-I);
ciclo=1;
paquetes_colisionados=0;
perdidas_buffer_lleno=0;
total_transmisiones=0;
paquetes_nodo_sink=0;
ranura=1;
colisiones_red=0;
paquete_recuperado=0;
t_arribo=0;
total_paquetes=0;
buffer_recorrido=zeros(1,K);
paquetes_grado=zeros(1,7);
retardo_grados=zeros(1,7);

%Variables usadas para las graficas
segundos=zeros(1,71);
posicion=1;
colisiones_tiempo=zeros(1,71);
lleno_tiempo=zeros(1,71);
perdidas_totales_tiempo=zeros(1,71);
ciclos_transcurridos=zeros(1,31);
paquetes_ciclo_transmitidos=zeros(1,71);
paquetes_ciclo_totales=zeros(1,71);
multiplo=1;
iteracion_ciclos=1;

for s=1:length(segundos)
segundos(s)=10000*s;
end

for c=1:length(ciclos_transcurridos)
ciclos_transcurridos(c)=10000*c;
end


%Generamos los grados y nodos
grados=Grado;
nodos=Nodo;
paquetes=Paquete;

buffer=zeros(1,K);
Grados_red=grados.empty;
Nodos_grado=nodos.empty;

%Array de Paquetes
Paquetes_red=paquetes.empty;
contador_paquete = 0; %Variable que nos ayuda a generar el núm del paquete

Ranuras=['R' 'T' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S' 'S']; %Ranuras para la calendarizacion consecutiva

for i=1:I   %Añadimos los grados a la red
    grados.id=i;
    grados.ranuras=Ranuras;
    Grados_red(i)=grados;

    for j=1:N   %Añadimos los nodos a cada grado en la red
        nodos.id=j;
        nodos.buffer=buffer(1,:);
        Nodos_grado(j)=nodos;
    end

    Grados_red(i).nodos=Nodos_grado;
end

  %t_arribo es mayor a t_sim, inicia el proceso de contención
        ranura_auxiliar=0;
            for i=I:-1:1 %For para llenado de ranuras y que sea una trasmision consecutiva
                grado_actual=Grados_red(i);
                
                if ranura_auxiliar>0
                    Ranuras=['S' Ranuras(1:20-1)]; %Para que siempre sea un tamaño 20
                end
                ranura_auxiliar=ranura_auxiliar+1;
                Grados_red(i).ranuras=Ranuras;
            end
       




% Inicio de los ciclos

tasa_paquetes2=tasa_paquetes*N*I; 
i=I;

while ciclo <=300000


%Generacion de paquetes cuando el ciclo sea 1 o t_arribo sea menor a t_sim

     while  t_arribo<=t_sim 

   
            

         contador_paquete = contador_paquete+1;
            
         grado_aleatorio=randi([1 I],1,1); %Seleccionamos numeros aleatorios para grado y nodo aleatorio
         nodo_aleatorio=randi([1 N],1,1);
    
         grado_seleccionado=Grados_red(grado_aleatorio); %Obtiene grado y nodo aleatorio de las clases creadas
         nodo_seleccionado=grado_seleccionado.nodos(nodo_aleatorio);
    
         espacio=false; %Variable booleana que verifica el espacio
         lugar=0;

         paquetes.grados = [];
         %Creamos el paquete, le colocamos su id y lo guardamos en el arreglo
         paquetes.id = contador_paquete;
         paquetes.id_nodo = nodo_aleatorio; %Colocamos el id del nodo correspondiente
         paquetes.t_arribo = t_arribo; %Coloca el instante de tiempo en el que se generó el paquete
         paquetes.grado_inicial=grado_aleatorio;
         Paquetes_red(contador_paquete) = paquetes;
         paquetes_grado(grado_aleatorio)=paquetes_grado(grado_aleatorio)+1;

        for bu=1:length(nodo_seleccionado.buffer)
            if nodo_seleccionado.buffer(bu)==0  %Comprobacion de buffer si esta lleno o hay espacio
                espacio=true;
                lugar=bu; %obtiene el lugar donde encontre un espacio
                break
            end
        end

        if espacio==true  %Si hay espacio, asigna paquete a grado y nodo aleatorio

            nodo_seleccionado.buffer(lugar)=contador_paquete;
            Grados_red(grado_aleatorio).nodos(nodo_aleatorio)=nodo_seleccionado;
            u=(1e6*rand())/1e6;
            nuevo_tiempo=-(1/tasa_paquetes2)*log(1-u);
            t_arribo=t_sim+nuevo_tiempo;    %Generamos nuevo t_arribo

        else %No hay espacio, se descarta el paquete
            Paquetes_red(contador_paquete).estado = "D";

            perdidas_buffer_lleno=perdidas_buffer_lleno+1;
            Grados_red(grado_aleatorio).paquete_perdido_buffer=Grados_red(grado_aleatorio).paquete_perdido_buffer+1;
            u=(1e6*rand())/1e6;
            nuevo_tiempo=-(1/tasa_paquetes2)*log(1-u);
            t_arribo=t_sim+nuevo_tiempo;    %Generamos nuevo t_arribo
        end
     end
     


    
    
        
            
          %Empezamos desde el grado mas alejado

        ranura_flag=true;  %Variables booleanas para comprobar ranura 
      
        
        transmision_vacia=false;
        nodos_transmisores=[];
     
            while ranura_flag==true

                for n=1:N
                    
                        Grados_red(i).nodos(n).contador_backoff=W;
                    
                end

                if Grados_red(i).ranuras(ranura) =='T' % En caso de caer en una transmision
                    for l=1:N %Verificacion de nodos y buffers que tengan paquetes que transmitir
                        for t=1:K
                            if Grados_red(i).nodos(l).buffer(t)~=0
                                nodos_transmisores=[nodos_transmisores Grados_red(i).nodos(l).id];   %Obtenemos el id de los nodos que tienen algo que transmitir
                                ranura_flag=false;  %Salimos del ciclo de busqueda de ranura
                                break
                            end
                        end
                    end
    
                    if isempty(nodos_transmisores) %Si no encuentra nodos transmisores
                        if i==1       %Si esta en el grado 1, completa el ciclo y aumenta el tiempo de la simulacion    
                            ranura=1;
                            t_sim=t_sim+T+Tc;
                            i=I;
                            ciclo=ciclo+1;
                            ranura_flag=false;
                            transmision_vacia=true; %Variable booleana para saber si hay o no algo que transmitir
                            break  %Sale del ciclo 
                        else           
                            i=i-1;   %Pasamos al siguiente grado en su siguiente ranura
                            ranura=ranura+1;
                            t_sim=t_sim+T;
                            ranura_flag=false;
                            transmision_vacia=true;
                            break;

                        end    
                    end
                
                else %No es transmision 
                    ranura=ranura+1;
                end
            end

        
        %Proceso de contención
        if transmision_vacia==false

            contadores=[];
            nodos_contendientes=[];
        
            for l=1:length(nodos_transmisores)   %Asignamos una variable aleatoria a cada contador de cada nodo
                contador=randi([0 W-1],1,1);
                Grados_red(i).nodos(nodos_transmisores(l)).contador_backoff=contador;
                contadores=[contadores Grados_red(i).nodos(nodos_transmisores(l)).contador_backoff]; %Ponemos el contador en cada nodo de un grado y los guardamos en un arreglo
            end
    
            ganador=min(contadores); %Selecciona el ganador/es de el proceso de contención
    
            for k=1:N  %Busca si gano un solo nodo o varios
                if Grados_red(i).nodos(k).contador_backoff==ganador
                    nodos_contendientes=[nodos_contendientes k]; %Variable que almacena el numero del nodo/nodos ganadores
                end
            end
    
            if length(nodos_contendientes)>1  %Si gano la contención mas de un nodo
                colisiones_red=colisiones_red+1;  %Aumenta numero de colisiones de la red
                Grados_red(i).colisiones_grado=Grados_red(i).colisiones_grado+1; %Aumenta numero de colisiones por grado
                Grados_red(i).paquete_perdido_colision=Grados_red(i).paquete_perdido_colision+length(nodos_contendientes); %Aumenta perdidas de paquetes por grado y en la red
               
                paquetes_colisionados=paquetes_colisionados + length(nodos_contendientes);
                %Cambia el estado de los paquetes por pérdidos
                
             
                for n=1:length(nodos_contendientes)
                    buffer_eliminado=Grados_red(i).nodos(nodos_contendientes(n)).buffer;   %Obtenemos buffer de los nodos que participaron
                    paquete_recuperado=buffer_eliminado(1);
                    Paquetes_red(paquete_recuperado).estado = "C";
                    buffer_eliminado(1)=0;
                    buffer_recorrido(1:14)=buffer_eliminado(2:K);    %Recorremos los paquetes del nodo para mantener estructura FIFO
                    Grados_red(i).nodos(nodos_contendientes(n)).buffer=buffer_recorrido; 
                end

                t_sim=t_sim+T;  %Aumentamos el tiempo de la simulacion  
        
                if i==1   %Si es grado uno, termina el ciclo y sumamos tiempo de ranuras de sleep
                    i=I;
                    ranura=1;
                    ciclo=ciclo+1;
                    t_sim=t_sim+Tc; 
                   
                else  %Caso contrario, pasa al siguiente grado en busca de paquetes a transmitir
                    i=i-1;
                    ranura=ranura+1;
                   
                end
            else  %En el caso de solo tener un nodo 
                
       

                %Eliminamos paquete del buffer ganador
                buffer_eliminado=Grados_red(i).nodos(nodos_contendientes).buffer;
                for b=1:K
                    if buffer_eliminado(b)~=0 %Eliminamos el paquete del buffer de los nodos
                       paquete_recuperado=buffer_eliminado(b); 
                       buffer_eliminado(b)=0;
                       break
                    end
                end

                %Asignamos el nuevo grado al que llegó el paquete
                Paquetes_red(paquete_recuperado).estado = "T";
                Paquetes_red(paquete_recuperado).grados = [Paquetes_red(paquete_recuperado).grados i]; 
               
                buffer_recorrido(1:14)=buffer_eliminado(2:K);
                Grados_red(i).nodos(nodos_contendientes).buffer=buffer_recorrido; %Recorremos los paquetes del nodo para mantener estructura FIFO

       
                 %Comprobar si es grado 1 o cualquier otro
                 
                 if i==1  %Condicion que hace cuando es grado 1 y transmite a nodo sink
                     Paquetes_red(paquete_recuperado).estado = "T"; 
    
                     total_transmisiones=total_transmisiones+1;
                     paquetes_nodo_sink=paquetes_nodo_sink+1;
                     Grados_red(i).paquete_transmitido_grado=Grados_red(i).paquete_transmitido_grado+1;
                     t_sim=t_sim+T+Tc;
                     Paquetes_red(paquete_recuperado).t_llegada = t_sim;
                     ranura=1;
                     ciclo=ciclo+1;
                     i=I;

                    
                     Paquetes_red(paquete_recuperado).retardo=Paquetes_red(paquete_recuperado).t_llegada-Paquetes_red(paquete_recuperado).t_arribo;
                     retardo_grados(Paquetes_red(paquete_recuperado).grado_inicial)=retardo_grados(Paquetes_red(paquete_recuperado).grado_inicial)+Paquetes_red(paquete_recuperado).retardo;
                    
                 else 
                     buffer_lleno=false;
                    %Coloca el paquete en el buffer del nodo del grado siguiente
                     for t=1:K
                         if Grados_red(i-1).nodos(nodos_contendientes).buffer(t)==0
                             Grados_red(i-1).nodos(nodos_contendientes).buffer(t)=paquete_recuperado;
                             total_transmisiones=total_transmisiones+1;
                             Grados_red(i).paquete_transmitido_grado=Grados_red(i).paquete_transmitido_grado+1;
                             buffer_lleno=false;
                         break
                 
                         else
                            buffer_lleno=true;
                            
                         end
                    end 


                     if buffer_lleno==true  %Si no encontro ningun espacio vacio, descarta todo el paquete y se aumenta tiempo de simulación
                         Paquetes_red(paquete_recuperado).estado = "D";
                         Paquetes_red(paquete_recuperado).id
                         perdidas_buffer_lleno=perdidas_buffer_lleno+1;    
                         
                         Grados_red(i).paquete_perdido_buffer=Grados_red(i).paquete_perdido_buffer+1;

                         t_sim=t_sim+T;
                         i=i-1;
                         ranura=ranura+1;
                 
                    else  %Si agrego el paquete al nodo exitosamente, aumenta tiempo y pasa al siguiente nodo
                        Paquetes_red(paquete_recuperado).estado = "T"; 
                         t_sim=t_sim+T;
                         i=i-1;
                         ranura=ranura+1;
                      
                     end
                 end
            end   %Termina el proceso de contencion
        end

if posicion<71
if t_sim>=segundos(posicion) && t_sim<segundos(posicion+1)
colisiones_tiempo(posicion)=paquetes_colisionados;
lleno_tiempo(posicion)=perdidas_buffer_lleno;
perdidas_totales_tiempo(posicion)=perdidas_buffer_lleno+paquetes_colisionados;
paquetes_ciclo_transmitidos(posicion)=paquetes_nodo_sink;
paquetes_ciclo_totales(posicion)=contador_paquete;
segundos(posicion)=t_sim;
posicion=posicion+1;
end
elseif posicion==71
colisiones_tiempo(posicion)=paquetes_colisionados;
lleno_tiempo(posicion)=perdidas_buffer_lleno;
perdidas_totales_tiempo(posicion)=perdidas_buffer_lleno+paquetes_colisionados;
paquetes_ciclo_transmitidos(posicion)=paquetes_nodo_sink;
paquetes_ciclo_totales(posicion)=contador_paquete;
segundos(posicion)=t_sim;
posicion=posicion+1;   
end




end




     
 %Comienza nuevo ciclo o termina si ya se llega a los 300000
 

%Retardo
promedio_retardo=retardo_grados./paquetes_grado;




%Graficas de la simulación

f=figure;

figure(1);
plot(segundos,colisiones_tiempo,':dm');
title("Grafica de paquetes perdidos por colisiones vs tiempo(segundos) con valores W = "+W+" N = "+N+" \lambda = "+tasa_paquetes);
xlabel('Segundos transcurridos');
ylabel("Paquetes perdidos");
f.Position(3:4) = [1280 720];
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Perdidas_colisiones.png']);
% saveas(gcf, whereToStore);

f=figure;
figure(2)
plot(segundos,lleno_tiempo,':db');
title("Grafica de paquetes perdidos por buffer lleno vs tiempo(segundos) con valores W = "+W+" N = "+N+" \lambda = "+tasa_paquetes);
xlabel('Segundos transcurridos');
ylabel("Paquetes perdidos");
f.Position(3:4) = [1280 720];
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Perdidas_buffer.png']);
% saveas(gcf, whereToStore);

f=figure;
figure(3)
plot(segundos,perdidas_totales_tiempo,':dr');
title("Grafica de paquetes perdidos totales vs tiempo(segundos) con valores W = "+W+" N = "+N+" \lambda = "+tasa_paquetes);
xlabel('Segundos transcurridos');
ylabel("Paquetes perdidos");
f.Position(3:4) = [1280 720];
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Perdidas_totales.png']);
% saveas(gcf, whereToStore);

f=figure;
figure(4)
plot(segundos,paquetes_ciclo_transmitidos,':pb',segundos,paquetes_ciclo_totales,':dr');
title("Troughput (Paquetes transmitidos vs paquetes totales por tiempo en segundos) con valores W = "+W+" N = "+N+" \lambda = "+tasa_paquetes);
xlabel('Segundos transcurridos');
ylabel("Numero de paquetes");
f.Position(3:4) = [1280 720];
legend('Paquetes transmitidos','Paquetes totales')
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Throughput.png']);
% saveas(gcf, whereToStore);



Probabilidad_perdida_colision=zeros(1,7);
Probabilidad_perdida_buffer=zeros(1,7);
Probabilidad_perdida_total=zeros(1,7);
total_paquetes_grado=0;



for p=1:I
total_paquetes_grado=Grados_red(p).paquete_transmitido_grado+Grados_red(p).paquete_perdido_buffer+Grados_red(p).paquete_perdido_colision;
Probabilidad_perdida_total(p)=(Grados_red(p).paquete_perdido_buffer+Grados_red(p).paquete_perdido_colision)/total_paquetes_grado;
Probabilidad_perdida_buffer(p)=Grados_red(p).paquete_perdido_buffer/total_paquetes_grado;
Probabilidad_perdida_colision(p)=Grados_red(p).paquete_perdido_colision/total_paquetes_grado;
end




%Perdidas por colisiones
f=figure;
figure(5)
plot(Probabilidad_perdida_colision,':pm');
title("Grafica de Probabilidad de Perdidas por colisiones por grado con valores W = "+W+" N = "+N+" \lambda = "+tasa_paquetes)
xlabel('Grados')
ylabel("Probabilidad de perdida");
f.Position(3:4) = [1280 720];
axis([0 8 0 1.1*max(Probabilidad_perdida_colision)+.1])
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Probabilidad_colisiones.png']);
% saveas(gcf, whereToStore);


%Perdidas por buffer lleno
f=figure;
figure(6)

plot(Probabilidad_perdida_buffer,':pblue');
title("Grafica de Probabilidad de Perdidas por buffer lleno por grado con valores W = "+W+" N = "+N+" \lambda = "+tasa_paquetes)
xlabel('Grados')
ylabel("Probabilidad de perdida");
f.Position(3:4) = [1280 720];
axis([0 8 0 1.1*max(Probabilidad_perdida_buffer)+.1])
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Probabilidad_buffer.png']);
% saveas(gcf, whereToStore);

%Perdidas totales
f=figure;
figure(7)
plot(Probabilidad_perdida_total,':pred');
title("Grafica de Probabilidad de Perdidas totales por grado con valores W = "+W+" N = "+N+" \lambda = "+tasa_paquetes)
xlabel('Grados')
ylabel("Probabilidad de perdida");
f.Position(3:4) = [1280 720];
axis([0 8 0 1.1*max(Probabilidad_perdida_total)+.1])
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Probabilidad_perdida_total.png']);
% saveas(gcf, whereToStore);

f=figure;
figure(8)
plot(promedio_retardo,':pblack');
title("Gráfica del retardo promedio por grado con parametros W = "+W+" N = "+N+" \lambda = "+tasa_paquetes)
xlabel('Grados')
ylabel("Retardo promedio [s]");
f.Position(3:4) = [1280 720];
axis([0 8 0 1.1*max(promedio_retardo)])
% DirectoryPath ='E:\Escuela\Octavo semestre\Redes inteligentes\proyecto final\graficas\6';
% whereToStore=fullfile(DirectoryPath,['Retardo.png']);
% saveas(gcf, whereToStore);

        


        



     





    
     













